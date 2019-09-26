{equals, isEmpty, isNil, join, match, merge, path, props, type} = R = require 'ramda' #auto_require: ramda
{fmap, sf2} = RE = require 'ramda-extras' #auto_require: ramda-extras
[] = [] #auto_sugar
qq = (f) -> console.log match(/return (.*);/, f.toString())[1], f()
qqq = (f) -> console.log match(/return (.*);/, f.toString())[1], JSON.stringify(f(), null, 2)
_ = (...xs) -> xs
_ = (...xs) -> xs

popsiql = require 'popsiql'

DEV = process.env.NODE_ENV == 'development'
# DEV = false

hasChanged = (lastState, currentState) -> ! equals lastState, currentState

subSelectIfDEV = (dataQuery, data) ->
	if DEV
		[missing, subData] = popsiql.utils.subSelect dataQuery, data
		return subData
	else return data

module.exports = (React, app, report) ->

	# Save info to print on error (eg. error during render), that will otherwise not be printed because of error
	reportStack = []
	pushToReportStack = (o) ->
		reportStack.unshift o
		reportStack.length = Math.min 100, reportStack.length # don't let array too big

	window.addEventListener 'error', ->
		for r in reportStack
			report {...r, ERROR: true}

	# React hook with state and effect keeping you subscribed to the dataQuery
	useData = (dataQuery, name = undefined) ->
		if !dataQuery.UI || !dataQuery.Data || !dataQuery.State
			throw new Error "your dataQuery is missing UI, Data or State:\n#{sf2 dataQuery}"

		# [uds, commitId] = app.getUDS()
		initialData = subSelectIfDEV dataQuery, app.getUDS()
		[state, setState] = React.useState initialData
		# hasInitialChange = false
		# initialUnsub = app.sub dataQuery, (() -> hasInitialChange = true), name + '_INITIAL'

		cacheCounter = 0
		React.useEffect ->
			# initialUnsub()

			handleChange = (data) ->
				cacheCounter++
				setState merge {cacheCounter}, subSelectIfDEV dataQuery, data

			# if hasInitialChange
			# 	qq -> 'hasInitialChange'
			# 	currentData = app.getUDS()
			# 	setState subSelectIfDEV dataQuery, currentData

			# Do shallow compare to see if data has changed since since initialData and trigger setState if it has
			data = app.getUDS()
			if initialData.UI != data.UI || initialData.Data != data.Data || initialData.State != data.State
				cacheCounter++
				setState merge {cacheCounter}, subSelectIfDEV dataQuery, data

			unsub = app.sub dataQuery, handleChange, name
			return ->
				qq -> 'unsub'
				unsub()

		# https://github.com/facebook/react/issues/14476#issuecomment-471199055
		# Note: we know dataQueries are small shallow objects anyway so JSON.stringify
		# shouldn't put any significant burden. But test it some time to be sure :)
		, [JSON.stringify(dataQuery)]

		return state

	# HOC that wraps a component and subscribes it with useData
	withData = (name, f) ->
		if type(name) != 'String' then throw new Error 'withData requires name as first argument'
		[dataQuery] = popsiql.utils.parseArguments f.toString()
		dataQuery.UI ?= {}
		dataQuery.Data ?= {}
		dataQuery.State ?= {}
		# fMemoed = React.memo f, equals
		return () ->
			dataToRender = useData dataQuery, name

			# dataToRender = subRes
			# dataToRender = if isNil res then [uiQuery, dataQuery, stateQuery]
			# else [res.UI, res.Data, res.State]

			t0 = performance.now()
			renderRes = f dataToRender
			time = {tot: performance.now() - t0}
			report {name: name, kind: 'withData', dataToRender, time, ts: t0}

			return renderRes


	_renderPre = (data) ->
		React.createElement 'pre', {style: {width: '100%'}}, sf2 data

	_renderPreMissing = (name, missing, data) ->
		React.createElement 'div', {style: {color: 'blue', position: 'absolute', top: 10, left: 10,
		zIndex: 999999999, border: '2px solid red', padding: 20, background: 'white'}},
			React.createElement 'div', {style: {color: 'red', fontSize: 20}}, "'#{name}' missing data!"
			fmap missing, (ar) ->
				path = join '.', ar
				React.createElement 'div', {key: path, style: {color: 'red', fontSize: 12}}, path

			React.createElement 'div', {}, 'Result from VM:'
			_renderPre data

	comp = (name, vm, deps, renderF) ->
		if !deps.VM then throw new Error "Missing VM deps in comp #{name}"
		{UI, Data, State, VM} = popsiql.utils.toDataQuery deps
		dataQuery = {UI, Data, State}

		lastCacheCounter = -1
		prev = null
		return (props) ->
			res = useData dataQuery, name

			# TODO: GÖR PROXY FÖR VM SÅ MAN SER OM MAN ACCESSAR NÅGON MAN INTE FRÅGADE EFTER

			time = {}
			t0 = performance.now()

			dataForVM = _ res.UI, res.Data, res.State


			vm0 = performance.now()
			vmRes = vm dataForVM..., prev
			time.vm = performance.now() - vm0
			tempPrev = {UI: res.UI, Data: res.Data, State: res.State, VM: vmRes}

			React.useEffect ->
				report {name, dataForVM, dataToRender, time: {...time, tot: performance.now() - t0}, ts: t0,
				noCacheChange: isNil(res.cacheCounter) || lastCacheCounter == res.cacheCounter}
				lastCacheCounter = res.cacheCounter
				prev = tempPrev
				return ->

			# TODO: turn this on 
			dataToRender = vmRes
			reportStack.push {name, dataForVM, dataToRender}

			if DEV
				[missing, dataToRender] = popsiql.utils.subSelect VM, vmRes

				if !isEmpty(missing) && vmRes.loading != true
					return _renderPreMissing name, missing, vmRes

			rf0 = performance.now()
			renderRes = renderF dataToRender
			time.rf = performance.now() - rf0

			return renderRes

	return {useData, withData, comp}


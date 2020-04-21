{equals, has, isEmpty, isNil, join, match, merge, path, prop, props, split, tail, test, type} = R = require 'ramda' #auto_require: ramda
{fmap, fmapI, sf2} = RE = require 'ramda-extras' #auto_require: ramda-extras
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

module.exports = (React, app, ops, report) ->

	# Save info to print on error (eg. error during render), that will otherwise not be printed because of error
	reportStack = []
	missings = {}
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
			return -> unsub()

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
		# Not removing this so developer needs to refresh when this happens = good engough

		# if !missings[name]
		# 	div = document.createElement 'div'
		# 	missings[name] = div
		# 	document.body.appendChild div

		# missDiv = missings[name]
		# missDiv.style.position = 'absolute'
		# missDiv.style.top = '10px'
		# missDiv.style.left = '10px'
		# missDiv.style.color = 'blue'
		# missDiv.style.zIndex = 9999999999999
		# missDiv.style.border = '2px solid red'
		# missDiv.style.padding = '20px'
		# missDiv.style.background = 'white'
		# missDiv.style.display = 'flex'
		# missDiv.style.flexDirection = 'column'

		# d1 = document.createElement 'div'
		# d1.textContent = "'#{name}' missing data!"
		# missDiv.appendChild d1

		# fmap missing, (ar) ->
		# 	path = join '.', ar
		# 	dp = document.createElement 'div'
		# 	dp.textContent = path
		# 	missDiv.appendChild dp

		# pre = document.createElement 'pre'
		# pre.style.width = '100%'
		# pre.textContent = sf2 data
		# missDiv.appendChild pre


		React.createElement 'div', {style: {color: 'blue', position: 'absolute', top: 10, left: 10,
		zIndex: 999999999, border: '2px solid red', padding: 20, background: 'white'}},
			React.createElement 'div', {style: {color: 'red', fontSize: 20}}, "'#{name}' missing data!"
			fmapI missing, (ar, idx) ->
				path = join '.', ar
				React.createElement 'div', {key: idx, style: {color: 'red', fontSize: 12}}, path

			React.createElement 'div', {}, 'Result from VM:'
			_renderPre data

	_renderPreMissingOps = (name, missing) ->
		React.createElement 'div', {style: {color: 'blue', position: 'absolute', top: 10, left: 10,
		zIndex: 999999999, border: '2px solid red', padding: 20, background: 'white'}},
			React.createElement 'div', {style: {color: 'red', fontSize: 20}}, "'#{name}' missing operations!"
			fmap missing, (ar) ->
				path = join '.', ar
				React.createElement 'div', {key: path, style: {color: 'red', fontSize: 12}}, path

	_renderPreVMAccess = (path) ->
		React.createElement 'div', {style: {color: 'blue', position: 'absolute', top: 10, left: 10,
		zIndex: 999999999, border: '2px solid red', padding: 20, background: 'white'}},
			React.createElement 'div', {style: {color: 'red', fontSize: 20}}, "Missing VM-dependency"
			React.createElement 'div', {style: {color: 'red', fontSize: 12}}, "vm.#{path}"

	comp = (name, vm, deps, renderF) ->
		if !deps.VM then throw new Error "Missing VM deps in comp #{name}"
		{UI, Data, State, VM, Ops} = popsiql.utils.toDataQuery deps
		dataQuery = {UI, Data, State}

		if DEV && Ops
			[missingOps, vmOps] = popsiql.utils.subSelect Ops, ops


		lastCacheCounter = -1
		prev = null
		return (props) ->
			res = useData dataQuery, name


			# TODO: GÖR PROXY FÖR VM SÅ MAN SER OM MAN ACCESSAR NÅGON MAN INTE FRÅGADE EFTER

			time = {}
			t0 = performance.now()

			dataForVMarr = _ res.UI, res.Data, res.State
			dataForVM = {UI: res.UI, Data: res.Data, State: res.State}

			vm0 = performance.now()
			vmRes = vm dataForVMarr..., prev
			time.vm = performance.now() - vm0
			tempPrev = {UI: res.UI, Data: res.Data, State: res.State, VM: vmRes}

			React.useEffect ->
				report {name, dataForVM, dataToRender, time: {...time, tot: performance.now() - t0}, ts: t0,
				noCacheChange: isNil(res.cacheCounter) || lastCacheCounter == res.cacheCounter}
				lastCacheCounter = res.cacheCounter
				prev = tempPrev
				return ->

			if missingOps && !isEmpty missingOps
				return _renderPreMissingOps name, missingOps

			# TODO: turn this on 
			dataToRender = vmRes
			reportStack.push {name, dataForVM, dataToRender}

			if DEV
				[missing, dataToRender] = popsiql.utils.subSelect VM, vmRes

				if !isEmpty(missing) && vmRes.loading != true
					return _renderPreMissing name, missing, vmRes
				# else if missings[name]
				# 	document.body.removeChild missings[name]
				# 	delete missings[name]

			if Ops
				if DEV then dataToRender.Ops = vmOps
				else dataToRender.Ops = ops
				
			if DEV
				VMandOps = merge VM, {Ops: vmOps}
				pathInVM = (path, o) ->
					if isEmpty path then return true
					else if test /@@/, path[0] then return true # workaround for: vm.records.@@functional/placeholder
					else if has path[0], o then pathInVM tail(path), o[path[0]]
					else if has path[0]+'〳', o then pathInVM tail(path), o[path[0]+'〳']
					else false

				dataToRenderOriginal = dataToRender
				getHandler =
					get: (o, prop, path) ->
						if ! pathInVM split('.', path), VMandOps
							throw new Error "vm.#{path} VM-dep"
						return o[prop]
				dataToRender = RE.recursiveProxy dataToRender, getHandler

			rf0 = performance.now()
			try
				renderRes = renderF dataToRender
			catch err
				[isMatch, path] = match /vm\.(.*?) VM-dep/, err.message
				if isMatch then return _renderPreVMAccess path
				else throw err

			time.rf = performance.now() - rf0

			return renderRes

	return {useData, withData, comp}


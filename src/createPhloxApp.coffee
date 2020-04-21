{always, curry, find, has, invoker, isEmpty, map, match, merge, partition, pick, reject, replace, type, values, whereEq, without} = R = require 'ramda' #auto_require: ramda
{change, isAffected, func, freduceO, $, isNilOrEmpty, sf0, customError} = RE = require 'ramda-extras' #auto_require: ramda-extras
[] = [] #auto_sugar
qq = (f) -> console.log match(/return (.*);/, f.toString())[1], f()
qqq = (f) -> console.log match(/return (.*);/, f.toString())[1], JSON.stringify(f(), null, 2)
_ = (...xs) -> xs

# TODO: Move parseArguments out of popsiql
popsiql = require 'popsiql'

PE = customError 'PhloxError'

module.exports = func
	ui: Object
	queries: Object
	lifters: Object
	invokers: Object
	config:
		runQuery: ->
		runLifter: ->
		runInvoker: ->
		debug: Boolean
		report: () -> # report callback for logging 
,
({ui, queries, lifters, invokers, config}) ->
	return new Phlox {ui, queries, lifters, invokers, config}


class Phlox
	constructor: ({ui, queries, lifters, invokers, config}) ->
		@ui = ui
		@state = {}
		@data = {}

		[qli, @noDepQueries, @noDepInvokers] = _prepare {ui, queries, lifters, invokers}
		[i, ql] = partition whereEq({type: 'invoker'}), qli
		@queriesAndLifters = ql
		@invokers = i
		@listeners = []
		# TODO: try resolve q/l/i into listeners !!

		window.setTimeout (=> @_runNoDepQueriesAndLifters()), 50

		# @initialUI = ui
		# @initialData = data
		@uiChanges = ui # initial ui is the initial change to spark everything off
		@dataChanges = {}
		@isRunning = false

		# @commitHistory = [] # optimization: cap this to X items in a smart way to keep index consistent

		@config = config

		@setCount = 0
		@flushCount = 0
		@isBlocked = false

		# @_flush() # initial flush
		window.requestAnimationFrame @_flush



	setUI: curry (delta, forceFlush=false) ->
		@setCount = @setCount + 1
		undo = {}
		@ui = change.meta delta, @ui, undo, @uiChanges
		if forceFlush then @_flush()
		# optimization 0: use changeM instead, reasoning: if views for some reason rerenders before flush, they'll partially get some new data, no problem with that?
		# optimization 1: call data-only dependencies before flush (requires rethink of viewModels)
		# optimization 2: move flush to WebWorker

	sub: (deps, cb, name = undefined, commitId = undefined) ->
		listener = if name then {deps, cb, name} else {deps, cb}
		@listeners.push listener

		# if ! isNil commitId
		# 	for id in [commitId..@commitHistory.length]
		# 		qq => _ name, id, isAffected deps, @commitHistory[id]
		# 		if isAffected deps, @commitHistory[id]
		# 			cb {UI: @ui, Data: @data, State: @state}
		# 			break

		# cb {UI: @ui, Data: @data, State: @state} # call first with current data
		# initialData = {UI: @ui, Data: @data, State: @state}
		return () => @listeners = without [listener], @listeners

		# unsub = () => @listeners = without [listener], @listeners
		# return [initialData, unsub]

	# getUDS: () -> return [{UI: @ui, Data: @data, State: @state}, @commitHistory.length]
	getUDS: () -> return {UI: @ui, Data: @data, State: @state}

	block: () -> @isBlocked = true
	unblock: () -> @isBlocked = false

	reset: (ui) ->
		# NOTE: not sure if this is a correct = full reset

		if !ui then throw new PE "initial ui needs to be an object, not #{ui}"
		# reset data
		for k,d of @data
			@_setData k, undefined

		# figure out the total delta needed for the reset
		totalDelta = {}
		for k, v of @ui
			if ui[k] then totalDelta[k] = ui[k]
			else totalDelta[k] = undefined

		@setUI totalDelta

		# re-run queries and lifters without dependencies
		window.setTimeout (=>@_runNoDepQueriesAndLifters()), 50




	_setData: (key) -> curry (data, forceFlush=false) =>
		@setCount = @setCount + 1
		undo = {}
		delta = {[key]: always data}
		@data = change.meta delta, @data, undo, @dataChanges
		if forceFlush then @_flush()

	_flush: =>
		if @isBlocked then return window.requestAnimationFrame @_flush
		if @flushCount > 0 && isEmpty(@uiChanges) && isEmpty(@dataChanges) then return window.requestAnimationFrame @_flush
		# if @flushCount > 0 && isEmpty(@uiChanges) && isEmpty(@dataChanges) then return

		# RUN
		setCount = @setCount
		# if flushCount == 0
		# 	dataChangesBefore = @initialData
		# else
		dataChangesBefore = @dataChanges
		uiChanges = @uiChanges

		@config.report {ts: performance.now(), name: 'flush-start', uiChanges, dataChangesBefore, setCount}

		r0 = performance.now()
		@setCount = 0

		time = {}
		ui = @ui
		@uiChanges = {} # reset so new uiChanges theoretically can happen during the run

		dataBefore = @data
		@dataChanges = {} # reset so new dataChanges theoretically can happen during the run

		ql0 = performance.now()
		[data, dataChanges, state, stateChanges, affected] = @_runQueriesAndLifters ui, uiChanges, dataBefore, dataChangesBefore
		time.ql = performance.now() - ql0

		@data = change dataChanges, @data
		@state = state

		time.r = performance.now() - r0
		# @config.report {ts: r0, name: 'run', uiChanges, dataChanges, stateChanges, setCount, time}

		# if flushCount == 0
		# 	@commitHistory.push {UI: uiChanges, Data: dataChanges, State: stateChanges}
		# else @commitHistory.push {UI: uiChanges, Data: dataChanges, State: stateChanges}

		i0 = performance.now()
		affectedInvokers = @_runInvokers ui, data, state, uiChanges, dataChanges, stateChanges
		time.i = performance.now() - i0

		# LISTENERS
		l0 = performance.now()
		affectedListeners = @_runListeners ui, data, state, uiChanges, dataChanges, stateChanges
		time.lis = performance.now() - l0
		time.tot = performance.now() - r0

		@config.report {ts: r0, name: 'flush-end', uiChanges, dataChangesBefore, dataChanges, stateChanges,
		setCount, time, affected: merge affected, {invokers: affectedInvokers, listeners: affectedListeners}}

		@flushCount++

		window.requestAnimationFrame @_flush


	_runQueriesAndLifters: (ui, uiChanges, dataBefore, dataChangesBefore) ->
		dataChanges = dataChangesBefore
		stateChanges = {}
		data = dataBefore
		state = @state
		affected = {queries: [], lifters: []}
		for x in @queriesAndLifters
			# qq -> x
			# qq -> isAffected x.deps, {UI: uiChanges, Data: dataChanges, State: stateChanges}
			if isAffected x.deps, {UI: uiChanges, Data: dataChanges, State: stateChanges}
				if x.type == 'query'
					affected.queries.push x.key
					clientRes = @config.runQuery x, {UI: ui, Data: data, State: state}, @_setData x.key
					if clientRes != undefined
						data = change.meta {[x.key]: clientRes}, data, {}, dataChanges
				else
					affected.lifters.push x.key
					lifterRes = @config.runLifter x, {UI: ui, Data: data, State: state}
					if lifterRes != undefined
						state = change.meta {[x.key]: lifterRes}, state, {}, stateChanges

		return [data, dataChanges, state, stateChanges, affected]

	_runInvokers: (ui, data, state, uiChanges, dataChanges, stateChanges) ->
		affected = []
		for i in @invokers
			if isAffected i.deps, {UI: uiChanges, Data: dataChanges, State: stateChanges}
				@config.runInvoker i, {UI: ui, Data: data, State: state}
				affected.push i
		return affected

	_runListeners: (ui, data, state, uiChanges, dataChanges, stateChanges) ->
		state = @state
		affected = []
		for l in @listeners
			if isAffected l.deps, {UI: uiChanges, Data: dataChanges, State: stateChanges}
				l.cb {UI: ui, Data: data, State: state}
				affected.push l
		return affected

	_runNoDepQueriesAndLifters: () ->
		console.log @
		for q in @noDepQueries # run queries without dependencies
			# optimization: do this async instead to improve time to first paint
			clientRes = @config.runQuery q, {UI: {}, Data: {}, State: {}}, @_setData q.key
			if clientRes != undefined
				@_setData q.key, clientRes

		for i in @noDepInvokers # run invokers without dependencies
			# optimization: do this async instead to improve time to first paint
			@config.runInvoker i, {UI: {}, Data: {}, State: {}}





###### Utils

_areResolved = (deps, resMap, level = 0) ->
	if level >= 2 then return true # {UI: {a: {a1}}} <-- we resolve to level a, not a1

	for k,v of deps
		if ! has k, resMap then return false
		else if v != null && ! _areResolved v, resMap[k], level + 1 then return false

	return true


_prepare = ({ui, queries, lifters, invokers}) ->
	toResolve = {}
	noDepQueries = []
	noDepInvokers = []

	# remove debug from ui
	ui = $ ui, freduceO {}, (acc, v, k) -> merge acc, {[replace /_debug$/, '', k]: v}

	_toQLI = (type, k, f) ->
		key = replace /_debug$/, '', k
		[UI, Data, State] = popsiql.utils.parseArguments f.toString()
		if has k, ui then throw new PE "#{type} '#{key}' also exists in initial ui, pick a unique key"
		if has(k, toResolve) || find(whereEq({key}), noDepQueries)
			throw new PE "'#{key}' exists twice in queries/lifters/invokers"
		qli = {type, key, f, debug: key != k, deps: reject isNilOrEmpty, {UI, Data, State}}
		if isEmpty qli.deps
			if type == 'lifter' then throw new PE "#{type}/#{k} is missing dependencies"
		return qli

	resMap = {UI: ui, Data: {}, State: {}}

	for k,f of queries
		qli = _toQLI 'query', k, f
		if isEmpty qli.deps
			noDepQueries.push qli
			resMap.Data[qli.key] = 1
		else toResolve[qli.key] = qli
	for k,f of lifters
		qli = _toQLI 'lifter', k, f
		toResolve[qli.key] = qli
	for k,f of invokers
		qli = _toQLI 'invoker', k, f
		if isEmpty qli.deps
			noDepInvokers.push qli
		else toResolve[qli.key] = qli

	res = []

	lap = 0
	while !isEmpty toResolve

		toDelete = []
		for k,o of toResolve
			if ! _areResolved o.deps, resMap then continue

			toDelete.push k

			if o.type == 'query'
				res.push o
				resMap.Data[o.key] = 1
			else if o.type == 'lifter'
				res.push o
				resMap.State[o.key] = 1
			else if o.type == 'invoker'
				res.push o

		for d in toDelete
			delete toResolve[d]

		if lap++ > 20
			console.error toResolve
			throw new PE "cannot resolve: #{sf0 values $ toResolve, map ({type, key}) -> type+'/'+key}"

	return [res, noDepQueries, noDepInvokers]

module.exports._prepare = _prepare


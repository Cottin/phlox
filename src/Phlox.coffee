{contains, filter, find, isEmpty, isNil, join, keys, lift, map, merge, prop, union, whereEq} = require 'ramda' #auto_require:ramda
{change, cc, changedPaths, fmapObjIndexed, freduce} = require 'ramda-extras' #auto_require:ramda-extras

utils = require './utils'

class Phlox
	constructor: ({lifters, viewModels, queriers, invokers, onQuery, onAction, initialData}) ->
		@data = {}
		@state = {}
		# @state = {queriers: null, lifters: null, viewModels: null}
		@log = []
		@changedViewModels = []

		@onQuery = onQuery
		@onAction = onAction

		@viewModelState = {}
		@queriersState = {}

		@__lifters = lifters
		@__viewModels = viewModels
		@__queriers = queriers

		@lifters = utils.prepareLifters lifters
		@viewModels = utils.prepareViewModels viewModels, @execIter
		@queriers = utils.prepareQueriers queriers
		@invokers = utils.prepareInvokers invokers

		hasNoDep = ({dataDeps, stateDeps}) ->
			isEmpty(dataDeps) && isEmpty(stateDeps)

		# VMs with no deps are executed directly and part of the initial state
		vmInitState = freduce @viewModels, {}, (mem, vm) ->
			if hasNoDep vm then merge mem, {"#{vm.key}": vm.f()}
			else mem

		@viewModelState = vmInitState

		forced =
			queriers: cc map(prop('key')), filter(hasNoDep), @queriers
			invokers: cc map(prop('key')), filter(hasNoDep), @invokers

		# Load initial data and force queriers and invokers without dependencies
		@change initialData, {label: 'LOAD INITIAL DATA'}, forced

		@listeners = []

		# window.requestAnimationFrame @rerender
		# window.setInterval @rerender, 10
		renderLoop = =>
			@rerender()
			window.requestAnimationFrame renderLoop
		window.requestAnimationFrame renderLoop

	subscribe: (listener, viewModel) =>
		if cc isNil, find(whereEq({key: viewModel})), @viewModels
			throw new Error "No viewModel named #{viewModel}"

		@listeners.push {name: viewModel, listener}

		return () =>
			@listeners = @listeners.filter ({listener: l}) -> l != listener

	change: (delta, {label, meta} = {}, forced = undefined) =>
		dataPaths = changedPaths delta
		msg = "CHANGE: #{join(',', dataPaths)}"
		if label then msg += " (label: #{label})"
		if meta then msg += "(meta: #{meta})"

		console.groupCollapsed msg
		console.log delta
		console.groupEnd()

		@data = change delta, @data
		@_dev_stateChanged?({data: @data, state: @state, viewModels: @viewModelState, queriers: @queriersState})
		
		statePaths = @lift dataPaths, forced


		# leave time for render if needed
		window.setTimeout @query(dataPaths, statePaths, forced), 0

	reset: (data = {}) =>
		currentKeys = keys @data
		changedKeys = union currentKeys, keys(data)
		@data = data

		console.groupCollapsed 'RESET', changedKeys
		console.log data
		console.groupEnd()

		statePaths = @lift changedKeys

		# leave time for render if needed
		window.setTimeout @query(changedKeys, statePaths), 0


	lift: (dataPaths, forced = {}) =>

		lift0 = performance.now()
		[delta_l, info_l] = utils.runLifters @lifters, @data, @state, dataPaths,
		forced['lifters']
		statePaths = keys delta_l
		@state = merge @state, delta_l
		liftTime = performance.now() - lift0
		liftTime_ = parseFloat(liftTime).toFixed(2)

		vm0 = performance.now()
		[delta_vm, info_vm] = utils.runViewModels @viewModels, @data, @state,
		dataPaths, statePaths, forced['viewModels']
		@viewModelState = merge @viewModelState, delta_vm
		vmTime = performance.now() - vm0
		vmTime_ = parseFloat(vmTime).toFixed(2)

		@changedViewModels = union @changedViewModels, keys(delta_vm)

		# todo: ta bort de här checkarna temporärt och optimera så att
		# 			det tar nära 0.01 ms att gå igenom items om inget behöver köras
		if !isEmpty delta_l
			console.groupCollapsed "lifters: (#{liftTime_}ms)", keys(delta_l)
			console.log info_l
			console.groupEnd()

		if !isEmpty delta_vm
			console.groupCollapsed "viewModels: (#{vmTime_}ms)", keys(delta_vm)
			console.log info_vm
			console.groupEnd()

		return statePaths

	query: (dataPaths, statePaths, forced = {}) => () =>
		queriers0 = performance.now()
		[delta_q, info_q] = utils.runQueriers @queriers, @data, @state,
		dataPaths, statePaths, forced['queriers']
		@forceQueriers = false
		@queriersState = merge @queriersState, delta_q
		queriersTime = performance.now() - queriers0
		queriersTime_ = parseFloat(queriersTime).toFixed(2)

		invokers0 = performance.now()
		[delta_i, info_i] = utils.runInvokers @invokers, @data, @state,
		dataPaths, statePaths, forced['invokers']
		invokersTime = performance.now() - invokers0
		invokersTime_ = parseFloat(invokersTime).toFixed(2)

		if !isEmpty delta_q
			console.groupCollapsed "queriers: (#{queriersTime_}ms)", keys(delta_q)
			console.log info_q
			console.groupEnd()

		if !isEmpty delta_i
			console.groupCollapsed "invokers: (#{invokersTime_}ms)", keys(delta_i)
			console.log info_i
			console.groupEnd()

		@execQueries delta_q
		@execInvokers delta_i

		@_dev_stateChanged?({data: @data, state: @state, viewModels: @viewModelState, queriers: @queriersState})

	execQueries: (queriers) =>
		fmapObjIndexed queriers, (q, k) =>
			res = @exec q, k, false

	execInvokers: (invokers) =>
		fmapObjIndexed invokers, (i, k) =>
			if ! isNil i 
				res = @exec i, k, true

			# if isThenable res
			# 	res.then (data) =>
			# 		@change {"#{k}": {$assoc: data}}, {label: "QUERIER_RESULT #{k}"}
			# else
			# 	@change {"#{k}": {$assoc: data}}, {label: "QUERIER_RESULT #{k}"}

		# TODO: execute invokers

	rerender: =>
		if isEmpty @changedViewModels then return

		render0 = performance.now()
		for l in @listeners
			if contains l.name, @changedViewModels
				# TODO: Kolla hur react renderar. Om setState är synkron kanske vi måste
				# göra en pull av viewModel från varje connectad komponent istället för
				# en push härifrån.
				# renderTime = ... förutsätter ju att setState är synkron
				l.listener @viewModelState[l.name]
		renderTime = performance.now() - render0

		@changedViewModels = []

		# detta kommer nog inte att funka, vi måste wrappa render i komponnenterna
		# på något sätt
		message = "RENDER #{parseFloat(renderTime).toFixed(2)}ms"
		if renderTime > 16 then console.warn message
		else console.log message

	renderAll: =>
		render0 = performance.now()
		for l in @listeners
			l.listener @viewModelState[l.name]
		renderTime = performance.now() - render0

		message = "RENDER #{parseFloat(renderTime).toFixed(2)}ms"
		if renderTime > 16 then console.warn message
		else console.log message

	forceQuery: (key) => @forcedQueriers = union @forcedQueriers, [key]

	# todo: remove commented out code if this works ok
	# exec: (query, caller) => @parser.exec query, caller
	# execIter: (iterable, caller) => @parser.execIter iterable, caller
	exec: (query, key, isInvoker) => @onQuery query, key, isInvoker
	execIter: (action, args, meta) => @onAction action, args, meta

	# TODO: reinitialize parser?
	reinitialize: ({lifters, viewModels, queriers, invokers}) =>
		liftersChanged = @__lifters != lifters
		viewModelsChanged = @__viewModels != viewModels
		queriersChanged = @__queriers != queriers
		invokersChanged = @__invokers != invokers

		if liftersChanged
			@__lifters = lifters
			@lifters = utils.prepareLifters lifters

		if viewModelsChanged
			@__viewModels = viewModels
			@viewModels = utils.prepareViewModels viewModels, @execIter

		if queriersChanged
			@__queriers = queriers
			@queriers = utils.prepareQueriers queriers

		if invokersChanged
			@__invokers = invokers
			@invokers = utils.prepareInvokers invokers

		forced =
			lifters: liftersChanged
			viewModels: viewModelsChanged
			queriers: queriersChanged
			invokers: invokersChanged

		@change {}, {label: 'RE-INITIALIZE'}, forced

	mock: ({viewModels}) ->
		@viewModelState = viewModels
		@renderAll()


module.exports = Phlox

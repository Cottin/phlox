{any, contains, difference, differenceWith, evolve, has, intersectionWith, into, isEmpty, keys, map, mapObjIndexed, merge, test, toPairs, union, update, where, without} = require 'ramda' #auto_require:ramda
{ymapObjIndexed, cc} = require 'ramda-extras'

# s, s -> b
# Returns true if x is y or if x starts with y or if y starts with x
# eg. _sameDep 'a', 'a' -> true
#			_sameDep 'a.b.c.d', 'a' -> true
#			_sameDep 'a', 'a.b.c.d' -> true
_sameDep = (x, y) ->
	if x == y then true
	else if test new RegExp("^#{y}\."), x then true
	else if test new RegExp("^#{x}\."), y then true
	else false


# o -> [o]
# Takes an object of semi-prepared lifters and sorts them in dependency order.
# eg. if lifter1 has a dependency on lifter2, lifter2 will be put before lifter1
prepareLifters = (lifters) ->
	res = [] # sorted lifters to return
	done = [] # array of keys of lifters that have been resolved
	lastCount = 0
	while true
		left = difference keys(lifters), done # lifters left to resolve
		if left.length == 0 then return res
		else if left.length == lastCount
			# if we did one pass without any lifters getting resolved => circular dep
			console.error 'Either you have a circular dependency in one or more lifters or a lifter is dependent on another lifter that does not exist. Lifters left to resolve:', left
			throw new Error 'Could not resolve lifters'
		lastCount = left.length

		for k in left
			{f, dataDeps, stateDeps} = lifters[k]
			noStateDeps = isEmpty stateDeps
			allStateDepsResolved = isEmpty differenceWith(_sameDep, stateDeps, done)
			if noStateDeps || allStateDepsResolved
				res.push {f, dataDeps, stateDeps, key: k}
				done.push k

# o -> [o]
# Expects a map of items and converts it into and array
_itemsObjToArray = (items) ->
	makeObj = ([key, v]) -> merge v, {key}
	return cc map(makeObj), toPairs, items

# o -> [o]
prepareQueriers = (queriers) -> _itemsObjToArray queriers
# A possible optimization: order queriers in dependency order. If you have
# queriers that depend on the result of other queriers that are synchronous,
# you could gain some benefit if they were ordered. It seems not worth it
# now though...

# o -> [o]
prepareInvokers = (invokers) -> _itemsObjToArray invokers

# o, f -> ,o
# Wraps the vm function and binds the actions to execIter
prepareViewModels = (vms, execIter) ->

	prepareAction = (vmKey) -> (action, actionKey) ->
		f = ->
			execIter action, arguments, {name: "#{vmKey}.#{actionKey}"}
			# caller gives error in safari when strict mode.. commenting out for now
			# if f.caller
			# 	console.log 'caller', f.caller
			# 	execIter action, arguments, {name: "#{vmKey}.#{actionKey}", caller: f.caller}
			# else
			# 	execIter action, arguments, {name: "#{vmKey}.#{actionKey}"}
		return f

	prepareVM = ([vmKey, vm]) ->
		f = ->
			res = vm.f.apply undefined, arguments
			return evolve {actions: mapObjIndexed(prepareAction(vmKey))}, res

		{dataDeps, stateDeps} = vm
		return {dataDeps, stateDeps, key: vmKey, f}

	return cc map(prepareVM), toPairs, vms

# o, [s], [s] -> [s]
# Returns a list of dependencies of item that is found in dataPaths and
# statePaths
_affectedDeps = (item, dataPaths, statePaths) ->
	dataPaths_ = intersectionWith _sameDep, item.dataDeps, dataPaths
	statePaths_ = intersectionWith _sameDep, item.stateDeps, statePaths
	return [dataPaths_, statePaths_]

# Runs the lifters with supplied data paths that changed.
# Returns a tuple [delta, info] where delta is a map of the lifters that were
# executed and what they returned and where info contains more info to debug,
# analyze and optimize the lifters.
runLifters = (lifters, data, state, dataPaths, isForced) ->
	delta = {}
	info = {}
	state_ = state
	# Note that lifters are pure functions and only run as a result of changes
	# in data paths. We should pass changes in state paths because it's the
	# lifters themselves that create this change
	statePaths = []
	for l in lifters
		l0 = performance.now()
		[dataDeps, stateDeps] = _affectedDeps l, dataPaths, statePaths
		if isEmpty(dataDeps) && isEmpty(stateDeps) && !isForced then continue

		res = l.f data, state_
		delta[l.key] = res
		state_[l.key] = res # update state to use in iter
		statePaths = union statePaths, [l.key] # update paths to use in iter

		time = performance.now() - l0
		info[l.key] = {time, paths: [dataDeps, stateDeps], result: res}
		if isForced then info[l.key].wasForced = true

	return [delta, info]

# Runs the "items" and returns a tuple [delta, info] like runLifters
_runItems = (items, data, state, dataPaths, statePaths, isForced) ->
	delta = {}
	info = {}
	for i in items
		i0 = performance.now()
		[dataDeps, stateDeps] = _affectedDeps i, dataPaths, statePaths
		if isEmpty(dataDeps) && isEmpty(stateDeps) && !isForced then continue

		res = i.f data, state
		delta[i.key] = res
		time = performance.now() - i0
		info[i.key] = {time, dataPaths: dataDeps, statePaths: stateDeps,
		result: res}
		if isForced then info[i.key].wasForced = true

	return [delta, info]

# All of these runs in the same way
runQueriers = _runItems
runInvokers = _runItems
runViewModels = _runItems


module.exports = {prepareLifters, prepareViewModels, prepareQueriers, prepareInvokers, runLifters, runQueriers, runInvokers, runViewModels}

	

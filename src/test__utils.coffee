assert = require 'assert'
{flip, type} = require 'ramda' #auto_require:ramda

utils = require './utils'

eq = flip assert.equal
deepEq = flip assert.deepEqual
throws = (f) -> assert.throws f, Error

# mock for performance in node when running mocha
global.performance = {now: -> Date.now()}

describe 'utils', ->

	describe 'prepareLifters', ->
		data = {a: 1, b: 2, c: 'three', d: {d1: 4}}
		l1 = {dataDeps: ['b'], stateDeps: ['l4'], f: ({b}, {l4}) -> b + l4}
		l2 = {dataDeps: [], stateDeps: ['l2'], f: ({}, {l2}) -> l2 * l2}
		l3 = {dataDeps: ['a', 'b'], stateDeps: [], f: ({a, b}) -> a + b}
		l4 = {dataDeps: [], stateDeps: ['l5'], f: ({}, {l5}) -> l5 + 1}
		l5 = {dataDeps: ['b'], stateDeps: [], f: ({b}) -> b * 2 }

		l6 = {dataDeps: ['a'], stateDeps: ['l7'], f: ({a}, {l7}) -> a + l7 }
		l7 = {dataDeps: ['c'], stateDeps: ['l8'], f: ({b}, {l8}) -> b + l8 }
		l8 = {dataDeps: ['d'], stateDeps: ['l6'], f: ({b}, {l6}) -> d + l6 }

		l9 = {dataDeps: [], stateDeps: ['l10'], f: ({}, {l10}) -> l10 + '!!' }
		l10 = {dataDeps: ['c'], stateDeps: ['l11.m.n.o'],
		f: ({c}, {l11: {m: {n: o}}}) -> "#{c} plus #{o}" }
		l11 = {dataDeps: ['a'], stateDeps: [], f: ({a}) -> {m: {n: {o: a + 3}}}}

		it 'simple case', ->
			res = utils.prepareLifters {l1, l3, l4, l5}
			eq l3.f, res[0].f
			eq l5.f, res[1].f
			eq l4.f, res[2].f
			eq l1.f, res[3].f

		it 'error for circular dep', ->
			throws -> utils.prepareLifters {l2}

		it 'error for circular dep (harder)', ->
			throws -> utils.prepareLifters {l6, l7, l8}

		it 'should handle nested paths', ->
			res = utils.prepareLifters {l9, l10, l11}
			eq l11.f, res[0].f
			eq l10.f, res[1].f
			eq l9.f, res[2].f

	describe 'prepareViewModels', ->
		execIter_ = (generator, args, name, caller) ->

			console.log "EXEC_ITER (#{name || ''})", caller, args
			iterable = generator.apply undefined, args
			res = iterable.next()
			return 1 + res.value

		it 'simple case', ->
			vm1 = ({a}, {b}) ->
				c: a + b
				actions:
					f1: ({c, d}) -> yield a + b + c + d
			vm1.deps = ['a', 'b']

			res = utils.prepareViewModels {vm1}, execIter_
			res_ = res[0].f({a: 1}, {b: 2})
			eq 3, res_.c
			callerFunction = ->
				eq 11, res_.actions.f1({c: 3, d: 4})
			callerFunction()

	describe 'prepareQueriers', ->
		# sometimes you might want to have circular dependencies for queriers
		# it 'throws if circular', ->
		# 	q1 = {dataDeps: ['q1'], stateDeps: [], f: () -> null}
		# 	throws -> utils.prepareQueriers {q1}
		it 'simple case', ->
			q1 = {dataDeps: ['q1'], stateDeps: [], f: () -> null}
			q2 = {dataDeps: ['q1'], stateDeps: ['a'], f: () -> null}
			res = utils.prepareQueriers {q1, q2}
			eq 'Array', type res
			eq 'q1', res[0].key

	describe 'runLifters', ->
		it 'simple case', ->
			lifters = [
				{dataDeps: ['a', 'b'], stateDeps: [], key: 'l1', f: ({a, b}) -> a + b}
				{dataDeps: [], stateDeps: ['l1'], key: 'l2', f: ({}, {l1}) -> l1 * l1}
			]

			[delta, info] = utils.runLifters lifters, {a: 1, b: 2}, {}, ['a', 'b']
			deepEq {l1: 3, l2: 9}, delta
			expected = 
				l1: {paths: [['a', 'b'], []], time: 0, result: 3}
				l2: {paths: [[], ['l1']], time: 0, result: 9}
			deepEq expected, info

	describe 'runQueriers', ->
		it 'simple case', ->
			queriers = [
				{dataDeps: ['a', 'b'], stateDeps: [], key: 'q1',
				f: ({a, b}) -> [a, b]}
				{dataDeps: [], stateDeps: ['l1'], key: 'q2',
				f: ({}, {l1}) -> l1}
			]

			[delta, info] = utils.runQueriers queriers, {a: 1, b: 2}, {l1: 3},
			['a'], ['l1']

			deepEq {q1: [1, 2], q2: 3}, delta
			expected =
				q1: {dataPaths: ['a'], statePaths: [], time: 0, result: [1, 2]}
				q2: {dataPaths: [], statePaths: ['l1'], time: 0, result: 3}
			deepEq expected, info

		it 'forced', ->
			queriers = [
				{dataDeps: ['a', 'b'], stateDeps: [], key: 'q1',
				f: ({a, b}) -> [a, b]}
			]

			[delta, info] = utils.runQueriers queriers, {a: 1, b: 2}, {l1: 3},
			[], [], ['q1']
			expected =
				q1: {dataPaths: [], statePaths: [], time: 0, result: [1, 2],
				wasForced: true}

			deepEq expected, info






















		
	# describe 'prepareItems', ->
	# 	it 'simple case', ->
	# 		items =
	# 			a: ({a, b}) -> a + b
	# 		items.a.deps = ['a', 'b']

	# 		items_ = utils.prepareItems items
	# 		eq 3, items_.a({a: 1, b: 2})

	# 	it 'throws if items are not functions', ->
	# 		items =
	# 			a: ({a, b}) -> a + b
	# 			b: {b1: -> 1}
	# 		items.a.deps = ['a', 'b']

	# 		throws -> utils.prepareItems items

	# 	it 'throws if deps are missing', ->
	# 		items =
	# 			a: ({a, b}) -> a + b
	# 			b: ({a, b}) -> a - b
	# 		items.a.deps = ['a', 'b']

	# 		throws -> utils.prepareItems items

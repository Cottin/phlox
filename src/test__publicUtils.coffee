assert = require 'assert'
{flip} = require 'ramda' #auto_require:ramda

publicUtils = require './publicUtils'

eq = flip assert.equal
feq = assert.equal
deepEq = flip assert.deepStrictEqual
fdeepEq = assert.deepStrictEqual
fdeepEq_ = (a, b) ->
	console.log a
	assert.deepStrictEqual a, b
throws = (f) -> assert.throws f, Error
# TODO: test-utils paket!!!


describe 'publicUtils', ->
	describe 'extractVMs', ->
		it 'simple', ->
			fdeepEq_ publicUtils.extractVMs({abc: 1, qweVM: 2}, {asdVM: 3, ert: 4}),
				{qweVM: 2, asdVM: 3}


assert = require 'assert'
{invoker, keys, map, pick, type} = R = require 'ramda' # auto_require: ramda
{} = RE = require 'ramda-extras' # auto_require: ramda-extras
[ːkey, ːdebug, ːtype, ːdeps] = ['key', 'debug', 'type', 'deps'] #auto_sugar
{fdeepEq_, throws} = RE = require 'testhelp' # auto_require: testhelp

{_prepare} = createPhloxApp = require './createPhloxApp'

describe 'createPhloxApp', ->
	describe.only '_prepare', ->
		it 'no same keys', ->
			throws /also exists/, ->
				_prepare {ui: {a: 1}, queries: {a: 2}, lifters: {b: 2}, invokers: {c: 3}}
			throws /exists twice/, ->
				_prepare {ui: {a: 1}, queries: {c: 2}, lifters: {b: 2}, invokers: {c: 3}}

		f0 = () -> 1
		fa = ({a}) -> 1
		fabc = ({a}, {b}, {c}) -> 1
		fb1 = ({}, {b: {b1}}) -> 1
		fd = ({}, {d}) -> 1

		it '1', ->
			res = _prepare {ui: {a: 2}, queries: {b: f0, d: fabc}, lifters: {c: fa},
			invokers: {e: fb1}}

			fdeepEq_ map(pick([ːkey, ːtype, ːdeps]), res), [
				{key: 'b', type: 'query', deps: {}},
				{key: 'c', type: 'lifter', deps: {UI: {a: null}}},
				{key: 'e', type: 'invoker', deps: {Data: {b: {b1: null}}}},
				{key: 'd', type: 'query', deps: {UI: {a: null}, Data: {b: null}, State: {c: null}}},
			]

		it 'debug', ->
			res = _prepare {ui: {a_debug: 2}, queries: {b_debug: f0, d: fabc}, lifters: {c_debug: fa},
			invokers: {e_debug: fb1}}

			fdeepEq_ map(pick([ːkey, ːdebug]), res), [
				{key: 'b', debug: true},
				{key: 'c', debug: true},
				{key: 'e', debug: true},
				{key: 'd', debug: false},
			]

		it 'cannot resolve', ->
			fc = ({}, {}, {c}) -> 1
			throws /cannot resolve/, ->
				_prepare {ui: {a: 1}, queries: {b: fc}, lifters: {c: fb1}, invokers: {d: fa}}



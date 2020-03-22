{invoker, map, match, pick, type} = R = require 'ramda' #auto_require: ramda
{} = RE = require 'ramda-extras' #auto_require: ramda-extras
[ːkey, ːdebug, ːdeps, ːtype] = ['key', 'debug', 'deps', 'type'] #auto_sugar
qq = (f) -> console.log match(/return (.*);/, f.toString())[1], f()
qqq = (f) -> console.log match(/return (.*);/, f.toString())[1], JSON.stringify(f(), null, 2)
_ = (...xs) -> xs

{fdeepEq, throws} = RE = require 'testhelp' # auto_require: testhelp

{_prepare} = createPhloxApp = require './createPhloxApp'

describe 'createPhloxApp', ->
	describe '_prepare', ->
		f0 = () -> 1
		fa = ({a}) -> 1
		fabc = ({a}, {b}, {c}) -> 1
		fb1 = ({}, {b: {b1}}) -> 1
		fd = ({}, {d}) -> 1

		it 'also exists', ->
			throws /also exists/, ->
				_prepare {ui: {a: 1}, queries: {a: 2}, lifters: {b: fa}, invokers: {c: fa}}
		it 'exists twice', ->
			throws /exists twice/, ->
				_prepare {ui: {a: 1}, queries: {c: 2}, lifters: {b: fa}, invokers: {c: fa}}


		it.only '1', ->
			res = _prepare {ui: {a: 2}, queries: {b: f0, d: fabc}, lifters: {c: fa},
			invokers: {e: fb1, f: f0}}

			fdeepEq map(pick([ːkey, ːtype, ːdeps]), res[0]), [
				{key: 'c', type: 'lifter', deps: {UI: {a: null}}},
				{key: 'e', type: 'invoker', deps: {Data: {b: {b1: null}}}},
				{key: 'd', type: 'query', deps: {UI: {a: null}, Data: {b: null}, State: {c: null}}},
			]

			fdeepEq map(pick([ːkey, ːtype, ːdeps]), res[1]), [
				{key: 'b', type: 'query', deps: {}}
			]

			fdeepEq map(pick([ːkey, ːtype, ːdeps]), res[2]), [
				{key: 'f', type: 'invoker', deps: {}}
			]

		it 'debug', ->
			res = _prepare {ui: {a_debug: 2}, queries: {b_debug: f0, d: fabc}, lifters: {c_debug: fa},
			invokers: {e_debug: fb1}}

			fdeepEq map(pick([ːkey, ːdebug]), res[0]), [
				{key: 'c', debug: true},
				{key: 'e', debug: true},
				{key: 'd', debug: false},
			]
			fdeepEq map(pick([ːkey, ːdebug]), res[1]), [
				{key: 'b', debug: true},
			]

		it 'cannot resolve', ->
			fc = ({}, {}, {c}) -> 1
			throws /cannot resolve/, ->
				_prepare {ui: {a: 1}, queries: {b: fc}, lifters: {c: fb1}, invokers: {d: fa}}



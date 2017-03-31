React = require 'react'
ReactDOM = require 'react-dom'
Pawpaw = require 'pawpaw'
{Phlox} = require 'phlox'

viewModels = require './base/viewModels'
queriers = require './base/queriers'
lifters = require './base/lifters'
createTree = require './base/parser'
require './style.css'
App = React.createFactory require('./App')


initialData =
	ui: {sortBy: 'name'}
	sync: {}

phlox = new Phlox {viewModels, queriers, parser, lifters, initialData}
parser = new Pawpaw createTree(phlox)
parser.logLevel = 999
phlox.parser = parser

window.app = phlox

# http://stackoverflow.com/questions/41448596/shortcut-to-clear-console-in-chrome-dev-tools-without-having-dev-tools-focused/41448862#41448862
doc_keyUp = (e) ->
	if (e.ctrlKey && e.keyCode == 68)
		console.clear()
document.addEventListener 'keyup', doc_keyUp, false

ReactDOM.render(App({phlox}), document.getElementById('root'))

if module.hot
	module.hot.accept ['./base/viewModels', './base/queriers', './base/lifters'], (updated) ->
		nextViewModels = require './base/viewModels'
		nextQueriers = require './base/queriers'
		nextLifters = require './base/lifters'
		phlox.reinitialize {viewModels: nextViewModels, queriers: nextQueriers, lifters: nextLifters}

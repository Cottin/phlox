{DOM: {div}, createElement: _} = React = require 'react'
{RestaurantListView_} = require './views/RestaurantListView'
{RestaurantView_} = require './views/RestaurantView'
{Phlox, PhloxProvider} = require 'phlox'
viewModels = require './base/viewModels'
queriers = require './base/queriers'
lifters = require './base/lifters'
createTree = require './base/parser'
Pawpaw = require 'pawpaw'


initialData =
	ui: {sortBy: 'name'}
	sync: {}

phlox = new Phlox {viewModels, queriers, parser, lifters, initialData}
parser = new Pawpaw createTree(phlox)
parser.logLevel = 999
phlox.parser = parser

window.app = phlox

App = React.createClass
  render: ->
    div {},
    	_ PhloxProvider, {phlox},
    		div {className: 'app__root'},
	    		_ RestaurantListView_
	    		_ RestaurantView_

module.exports = App



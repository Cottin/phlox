{DOM: {div, a}, createElement: _} = React = require 'react'
PureRenderMixin = require 'react-addons-pure-render-mixin'
{connect} = require 'phlox'
{fmapObjIndexed} = require 'ramda-extras' #auto_require:ramda-extras
{test} = require 'ramda' #auto_require:ramda
cn = require 'classnames'

# to move: react-coffee
createComp = (f, name) ->
	React.createClass
		displayName: name
		# mixins: [PureRenderMixin]
		render: -> f @props, @context

createComps = (connect, o) ->
	fmapObjIndexed o, (f, k) ->
		comp = createComp f, k
		if test /_$/, k then connect comp, k
		else comp

DateView = ({date}) ->
	div {}, date


DateView_ = DateView

module.exports = createComps connect, {DateView_}







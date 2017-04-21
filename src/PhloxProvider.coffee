{Children, createClass} = require 'react'
{object} = require 'prop-types'

PhloxProvider = createClass
	displayName: 'PhloxProvider'

	propTypes:
		phlox: object

	childContextTypes:
		phlox: object

	getChildContext: ->
		phlox: @props.phlox

	render: ->
		Children.only(@props.children)

module.exports = PhloxProvider

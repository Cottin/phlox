{Children, createClass, PropTypes: {object}} = require 'react'

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

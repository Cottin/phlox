{Children} = require 'react'
createReactClass = require 'create-react-class'
{object} = require 'prop-types'

PhloxProvider = createReactClass
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

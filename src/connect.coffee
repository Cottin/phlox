{createClass, createElement: _, PropTypes: {object}} = require 'React'
{} = require 'ramda' #auto_require:ramda

connect = (component, viewModelName) ->
	createClass
		displayName: "Connect(#{getDisplayName(component)})"

		contextTypes:
			phlox: object.isRequired

		getInitialState: ->
			@context.phlox.state[viewModelName] || null

		componentWillMount: ->
			@_unsubscribe = @context.phlox.subscribe @changed, viewModelName

		componentWillUnmount: ->
			@_unsubscribe()

		changed: (newState) ->
			@setState newState

		render: ->
			_ component, @state

getDisplayName = (WrappedComponent) ->
  WrappedComponent.displayName || WrappedComponent.name || 'Component'

module.exports = connect

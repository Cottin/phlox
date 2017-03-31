{createClass, createElement: _, PropTypes: {object}} = require 'React'
{} = require 'ramda' #auto_require:ramda

connect = (component, viewModelName) ->
	createClass
		displayName: "Connect(#{getDisplayName(component)})"

		contextTypes:
			phlox: object.isRequired

		getInitialState: ->
			@context.phlox.viewModelState[viewModelName] || null

		# TODO:
		# shouldComponentUpdate: ->

		componentWillMount: ->
			@_unsubscribe = @context.phlox.subscribe @changed, viewModelName

		componentWillUnmount: ->
			@_unsubscribe()

		changed: (newState) ->
			@setState newState

		# Do week need something like this?
		# https://github.com/reactjs/react-redux/blob/master/src/components/connect.js#L353

		render: ->
			_ component, @state

getDisplayName = (WrappedComponent) ->
  WrappedComponent.displayName || WrappedComponent.name || 'Component'

module.exports = connect

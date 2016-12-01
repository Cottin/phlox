{DOM: {div, a}, createElement: _} = React = require 'react'
PureRenderMixin = require 'react-addons-pure-render-mixin'
{connect} = require 'phlox'
{ymapObjIndexed, ymap} = require 'ramda-extras'
{T, add, isNil, map, range, test} = require 'ramda' #auto_require:ramda
cn = require 'classnames'

# to move: react-coffee
createComp = (f, name) ->
	React.createClass
		displayName: name
		mixins: [PureRenderMixin]
		render: -> f @props, @context

createComps = (connect, o) ->
	ymapObjIndexed o, (f, k) ->
		comp = createComp f, k
		if test /_$/, k then connect comp, k
		else comp

reviews_ = [
	id: 1
	text: 'Not really my thing… Too little burger and too little beer.'
	stars: 1
	date: '13 mar 2017'
	user: {
		name: 'Martin'
		color: '#8DDA91'
		initials: 'M'
	}
,
	id: 2
	text: 'Great food but a bit noisy place'
	stars: 4
	date: '18 mar 2017'
	user: {
		name: 'Tina'
		color: '#C48DDA'
		initials: 'T'
	}
]

RestaurantView = ({rest, actions}) ->
	if isNil(rest)
		return div {}, 'Select a restaurant to the left'

	div {className: 'rv'},
		renderRest rest
		div {className: 'rv__add-review'}, 'ADD REVIEW'
		map renderReview, rest.reviews

renderRest = ({name, stars, address, desc, color}) ->
	div {},
		div {className: 'rv__title'}, name
		div {className: 'rv__address'}, address
		div {className: 'rv__desc'}, desc
		div {className: 'rv__rating', style: {background: color}}, stars

renderReview = ({id, text, stars, date, user}) ->
	div {key: id, className: 'rev'},
		renderUser user
		div {className: 'rev__right'},
			div {className: 'rev__text'}, text
			div {className: 'rev__bottom'},
				div {className: 'rev__date'}, date
				renderRating stars

renderUser = ({name, color, initials}) ->
	div {className: 'usr'},
		div
			className: 'usr__initials'
			style: {background: color}
		, initials
		div {className: 'usr__name'}, name

renderRating = (stars) ->
	div {className: 'rat'},
		ymap range(0, stars), -> '★'
		ymap range(stars, 5), -> '☆'




RestaurantView_ = RestaurantView

module.exports = createComps connect, {RestaurantView_}







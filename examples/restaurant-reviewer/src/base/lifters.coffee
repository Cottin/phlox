{compose, curry, filter, find, has, isEmpty, isNil, mean, merge, pluck, prop, reverse, sortBy, toLower, type, values, whereEq} = R = require 'ramda' #auto_require:ramda
{cc, ymapObjIndexed, ymap} = require 'ramda-extras'

denorm = curry (data, o) ->
	ymapObjIndexed o, (v, k) ->
		if ! has k, data then return v

		if type(v) == 'Array'
			return ymap (i) ->
				if has i, data[k] then data[k][i]
				else i

		if has v, data[k] then data[k][v]
		else v

denormWithMappning = curry (data, mappings, o) ->
	ymapObjIndexed o, (v, k) ->
		newData = mappings


restaurantsSorted = ({ui: {sortBy}, restaurants, reviews}, {}) ->
	restaurants_ = ymapObjIndexed restaurants, (v, k) ->
		rs = cc filter(whereEq({restaurant: parseInt(k)})), values, reviews
		stars = pluck 'stars', rs
		avg = if isEmpty stars then 0 else Math.round(mean(stars) * 10) / 10
		color = if avg >= 4.0 then '#FF217B' else '#6128BC'
		merge v, {reviews: rs, stars: avg, color}

	restaurants__ = values restaurants_
	if sortBy == 'name'
		R.sortBy compose(toLower, prop('name')), restaurants__
	else if sortBy == 'stars'
		cc reverse, R.sortBy(prop('stars')), restaurants__
	else
		restaurants__

selectedRestaurant = ({ui: {selected}}, {restaurantsSorted}) ->
	if isNil(restaurantsSorted) || isNil(selected) then return null
	find whereEq({id: selected}), restaurantsSorted


module.exports = {
	restaurantsSorted: {dataDeps: ['ui.sortBy', 'restaurants', 'reviews'], stateDeps: [], f: restaurantsSorted}
	selectedRestaurant: {dataDeps: ['ui.selected'], stateDeps: ['restaurantsSorted'], f: selectedRestaurant}
}

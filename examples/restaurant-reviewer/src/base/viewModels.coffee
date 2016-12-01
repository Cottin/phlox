
RestaurantListView_ = ({ui: {sortBy}}, {restaurantsSorted}) ->
	rests: restaurantsSorted
	sortBy: sortBy
	actions:
		sortBy: (sortBy) -> yield {UI: {sortBy: sortBy.toLowerCase()}}
		select: (id) -> yield {UI: {selected: id}}

RestaurantView_ = ({}, {selectedRestaurant}) ->
	rest: selectedRestaurant


module.exports = {
	RestaurantListView_: {dataDeps: ['ui.sortBy'], stateDeps: ['restaurantsSorted'], f: RestaurantListView_}
	RestaurantView_: {dataDeps: [], stateDeps: ['selectedRestaurant'], f: RestaurantView_}
}

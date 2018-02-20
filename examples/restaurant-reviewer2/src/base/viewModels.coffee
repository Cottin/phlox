
RestaurantListView_ = ({ui: {sortBy}}, {restaurantsSorted}) ->
	rests: restaurantsSorted
	sortBy: sortBy
	actions:
		sortBy: (sortBy) -> yield {UI: {sortBy: sortBy.toLowerCase()}}
		select: (id) -> yield {UI: {selected: id}}

RestaurantView_ = ({}, {selectedRestaurant}) ->
	rest: selectedRestaurant
	actions:
		newReview: () ->
			emptyReview = {stars: 1, text: '', user: '',
			restaurant: selectedRestaurant.id}
			yield {Write: {reviewToEdit: {$assoc: emptyReview}}}

RestaurantEditView_ = ({}, {selectedRestaurant}) ->
	restaurant: selectedRestaurant

ReviewEditView_ = ({reviewToEdit}, {selectedRestaurant}) ->
	review: reviewToEdit
	restaurant: selectedRestaurant
	actions:
		cancel: -> yield {Write: {reviewToEdit: null}}
		create: (review) ->
			yield {Review: 'create', data: review}
			yield {Write: {reviewToEdit: null}}
		change: (delta) -> yield {Write: {reviewToEdit: delta}}

# only here to make sure you get data from a vm that has no dependencies
DateView_ = ({}, {}) ->
	return {date: new Date().toJSON().slice(0,10)}
	

#auto_export:phlox
module.exports = {
	RestaurantListView_: {dataDeps: ['ui.sortBy'], stateDeps: ['restaurantsSorted'], f: RestaurantListView_},
	RestaurantView_: {dataDeps: [], stateDeps: ['selectedRestaurant'], f: RestaurantView_},
	RestaurantEditView_: {dataDeps: [], stateDeps: ['selectedRestaurant'], f: RestaurantEditView_},
	ReviewEditView_: {dataDeps: ['reviewToEdit'], stateDeps: ['selectedRestaurant'], f: ReviewEditView_},
	DateView_: {dataDeps: [], stateDeps: [], f: DateView_}
}
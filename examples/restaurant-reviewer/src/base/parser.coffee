
createTree = (app) ->

	# Data:
	# 	change: ({delta}) -> app.change delta

	Write: -> (delta) -> app.change delta
	UI: -> (delta) -> app.change {ui: delta}


	Api: ->
		URL = 'http://localhost:3030/api'
		get: ({type, id}) ->
			url = URL + '/' + type + if id then '/' + id else ''
			res = yield fetch url
			json = yield res.json()
			return json

	# kanske tänka om det här lite. Vi har inte modeller, vi har en enklare
	# arkitektur utan cachning
	Model:
		Read: ({type}) ->
			yield {Write: {sync: {"#{type}": {read: true}}}}
			try
				os = yield {Api: 'get', type}
				yield {Write: {sync: {"#{type}": {read: false}}}}
				# yield {Write: {"sync/#{type}/read": false}} <- nice idea?
				# only needed if we want some kind of caching:
				# yield {Write: {"#{type}": os}}
				return os
			catch err
				yield {Write: {sync: {"#{type}": {read: err}}}}
				# yield {Data: 'change', delta: {Customer: {1: {$assoc: data}}
				# yield {Write: {Customer: {1: {$assoc: data}}}}
				# yield {Write: {'Customer/1': {$assoc: data}}}}
				# yield {Write: {'Customer/1': $assoc(data)}}}


	Restaurant:
		get: ->
			return yield {Model: 'Read', type: 'Restaurant'}

	Review:
		get: ->
			return yield {Model: 'Read', type: 'Review'}

module.exports = createTree

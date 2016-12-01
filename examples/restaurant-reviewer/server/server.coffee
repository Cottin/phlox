express = require 'express'
bodyParser = require 'body-parser'
{} = require 'ramda' # auto_require:ramda
# {cc} = require 'ramda-extras'

cors = (req, res, next) ->
	res.set 'Access-Control-Allow-Origin', req.headers.origin
	res.set 'Access-Control-Allow-Headers', 'Content-Type, Authorization, X-Requested-With, Content-Length, Accept, Origin'
	res.set 'Access-Control-Allow-Methods', 'GET, POST, OPTIONS, PUT, PATCH, DELETE'
	res.set 'Access-Control-Allow-Credentials', 'true'
	res.set 'Access-Control-Max-Age', 5184000
	next()

##### MIDDLEWARE
app = express()

app.set('port', (process.env.PORT || 3030));

app.all '*', (req, res, next) ->
	console.log "\n#{req.method} #{req.path}"
	next()

app.all '*', cors
app.use bodyParser.json()

##### DATA
mockData = require '../src/base/mockData'

##### ROUTES
app.get '/api/restaurant', (req, res) -> res.json mockData.restaurants
app.get '/api/review', (req, res) -> res.json mockData.reviews


##### START
server = app.listen app.get('port'), ->
	host = server.address().address
	port = server.address().port
	console.log 'Example app listening at http://%s:%s', host, port


	
module.exports = app

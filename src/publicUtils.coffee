{mergeAll, pickBy, test} = require 'ramda' #auto_require:ramda
{doto} = require 'ramda-extras' #auto_require:ramda-extras

extractVMs = (xs...) ->
	doto xs, mergeAll, pickBy (_, k) -> test /VM$/, k


#auto_export:none_
module.exports = {extractVMs}
restaurants = ({}, {}) -> {Restaurant: 'get'}

reviews = ({}, {}) -> {Review: 'get'}

#auto_export:phlox
module.exports = {
	restaurants: {dataDeps: [], stateDeps: [], f: restaurants},
	reviews: {dataDeps: [], stateDeps: [], f: reviews}
}
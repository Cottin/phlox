restaurants = ({}, {}) -> {Restaurant: 'get'}

reviews = ({}, {}) -> {Review: 'get'}

module.exports = {
	restaurants: {dataDeps: [], stateDeps: [], f: restaurants}
	reviews: {dataDeps: [], stateDeps: [], f: reviews}
}

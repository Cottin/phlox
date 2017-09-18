{isNil} = require 'ramda' #auto_require:ramda

defaultSelected = ({ui: {selected}}, {}) ->
	if isNil selected
		return {UI: {selected: 1}}

#auto_export:phlox
module.exports = {
	defaultSelected: {dataDeps: ['ui.selected'], stateDeps: [], f: defaultSelected}
}
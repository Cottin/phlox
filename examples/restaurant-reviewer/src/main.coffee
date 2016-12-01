React = require 'react'
ReactDOM = require 'react-dom'
App = React.createFactory require('./App')
require './style.css'

ReactDOM.render(App(), document.getElementById('root'))

router = require './router'
express = require 'express'

module.exports = ->
    app = express()
    router app
    app.listen 9999
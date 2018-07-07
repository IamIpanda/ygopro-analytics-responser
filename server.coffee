router = require './router'
express = require 'express'
moment = require 'moment'

module.exports = (port) ->
    console.log "Analytics server on port #{port} started on #{moment().format('YYYY-MM-DD hh:mm:ss')}"
    app = express()
    router app
    app.listen port
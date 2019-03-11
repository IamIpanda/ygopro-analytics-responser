router = require './router'
express = require 'express'
moment = require 'moment'

formatQuery = (query) ->
    queries = []
    for key in Object.keys(query)
        queries.push "#{key} = #{query[key]}"
    if queries.length == 0 then "" else ", " + queries.join ", "

module.exports = (port) ->
    console.log "Analytics server on port #{port} started on #{moment().format('YYYY-MM-DD hh:mm:ss')}"
    app = express()
    router app
    app.get '*', (req, res) ->
        console.log "NOT FOUND - #{req.method} #{decodeURIComponent(req._parsedUrl.pathname)}#{formatQuery(req.query)}"
        res.send "Can't find path #{decodeURIComponent(req._parsedUrl.pathname)}", 404
    app.listen port
redis = require './redis'
watcher = require './watcher'
middleware = require './middlewares'

getPeriod = (type) ->
    switch type
        when "today" then return 0
        when "yesterday" then return 1
        when "day" then return 1
        when "week" then return 7
        when "halfmonth" then return 15
        when "season" then return -999
    return 1

module.exports = (app) ->
    app.get '/counter_all', (req, res) ->
        data = await middleware.getSummaryCounters()
        res.json data

    app.get '/counter', (req, res) ->
        source = req.query.source || "unknown"
        period = getPeriod req.query.period || req.query.type 
        data = await redis.load "count", source, period
        res.json data

    app.get '/deck', (req, res) ->
        source = req.query.source || "unknown"
        period = getPeriod req.query.period || req.query.type 
        data = await redis.load "deck", source, period
        res.json data

    app.get '/single', (req, res) ->
        source = req.query.source || "unknown"
        period = getPeriod req.query.period || req.query.type 
        category = req.query.category || "monster"
        data = await redis.load "single", source, period, category
        res.json data

    app.post '/reset', (req, res) ->
        res.text 'ok'
        watcher()
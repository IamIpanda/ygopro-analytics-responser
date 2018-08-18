redis = require './redis'
watcher = require './watcher'

getPeriod = (type) ->
    switch type
        when "today" then return 0
        when "yesterday" then return 1
        when "day" then return 1
        when "week" then return 7
        when "halfmonth" then return 15
        when "season" then return -1
    return 1

module.exports = (app) ->
    app.get '/counter', (req, res) ->
        source = req.query.source || "unknown"
        period = getPeriod req.query.period
        data = await redis.load "count", source, period
        res.json data

    app.get '/deck', (req, res) ->
        source = req.query.source || "unknown"
        period = getPeriod req.query.period
        data = await redis.load "deck", source, period
        res.json data

    app.get '/single', (req, res) ->
        source = req.query.source || "unknown"
        period = getPeriod req.query.period
        category = req.query.category || "monster"
        data = await redis.load "deck", source, period, category
        res.json data

    app.post '/reset', (req, res) ->
        await watcher()
        res.text 'ok'
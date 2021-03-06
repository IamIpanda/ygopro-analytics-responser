pg = require './pg'
redis = require './redis'
middleware = require './middlewares'
moment = require 'moment'

watcher = ->
    console.log "Analytics watcher started on #{moment().format('YYYY-MM-DD hh:mm:ss')}"
    for query from pg.query()
        query.result = await query.promise
        redis.save query
    console.log "Analytics wathcer is collecting counter data..."
    await middleware.collectSummaryCounters()
    console.log "Analytics watcher ended on #{moment().format('YYYY-MM-DD hh:mm:ss')}"

module.exports = watcher
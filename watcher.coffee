pg = require './pg'
redis = require './redis'
moment = require 'moment'

watcher = ->
    console.log "Analytics wathcer started on #{moment().format('YYYY-MM-DD hh:mm:ss')}"
    for query from pg.query()
        query.result = await query.promise
        redis.save query 
    console.log "Analytics wathcer ended on #{moment().format('YYYY-MM-DD hh:mm:ss')}"
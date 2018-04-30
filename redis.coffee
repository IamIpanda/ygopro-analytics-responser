redis = require 'redis'
config = require './config'
task = config.task
client = redis.createClient config.redis

module.exports.save = (query) ->
    i = 0
    for part from query.result
        name = task.table[i++]
        typeName = "#{name}_#{query.source}_#{query.period}"
        switch name
            when 'deck'
                obj = part
                continue unless obj
                obj.forEach (child) ->
                    delete child.time
                    delete child.timeperiod
                json = JSON.stringify obj 
                client.set typeName, json
                console.log "Setting redis #{typeName}"
            when 'count'
                obj = part.rows[0] 
                continue unless obj
                count = obj.count
                continue unless count
                client.set typeName, count
                console.log "Setting redis #{typeName}"
            when 'single'
                j = 0
                for childPart from part
                    category = ['monster', 'spell', 'trap', 'side', 'ex'][j++]
                    subTypeName = typeName + "_" + category
                    obj = childPart.rows
                    json = JSON.stringify obj
                    client.set subTypeName, json
                    console.log "Setting redis #{subTypeName}"

standardRedisPromise = (typeName) ->
    new Promise (resolve, reject) ->
        client.get typeName, (err, reply) ->
            if err then reject err else resolve reply


module.exports.load = (name, source, period, category) ->
    typeName = "#{name}_#{source}_#{period}"
    switch name
        when 'deck'
            return standardRedisPromise typeName
        when 'count'
            return standardRedisPromise typeName
        when 'single'
            typeName += "_#{category}"
            return standardRedisPromise typeName
    null
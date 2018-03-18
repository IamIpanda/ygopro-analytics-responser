redis = require 'redis'
config = require './config.json'
task = config.task
client = redis.createClient config.redis

module.exports.save = (query) ->
    i = 0
    for part from query.result
        name = task.table[i++]
        typeName = "#{name}_#{query.source}_#{query.period}"
        switch name
            when 'deck'
                obj = part.rows
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
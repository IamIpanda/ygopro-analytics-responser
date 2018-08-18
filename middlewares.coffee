# This file contains all the compromise code for fitting old style ygoruby-analytics.
# If possible, this file should be removed in the future.
# This file contains following contents:
# 1, add card name in all possible names to single analytics query.
# 2, add an redis and a polymerization for counter query.
# All the function call in this file is directly added to the other files.

path = require 'path'
data = require 'ygojs-data'
redis = require './redis'
config = require './config.json'

data.Environment.setConfig databasePath: path.join __dirname, "ygopro-database/locales/"
LANGUAGE_NAMES = ['zh-CN', 'en-US', 'ja-JP']
PERIOD_NAMES = {0: 'today', 1: 'day', 7: 'week', 15: 'halfmonth', 30: 'month', '-999': 'season'}
COUNTER_SUMMARY_NAME = "count_all"

cardNames = {}

preloadCardNames = ->
    for lang in LANGUAGE_NAMES
        environment = new data.Environment lang
        environment.loadAllCards()
        for id of environment.cards
            name = environment[id].name
            cardNames[id] = {} unless cardNames[id]
            cardNames[id][lang] = name

addCardName = (query) ->
    query.rows.forEach (data) -> data.name = cardNames[data.id]
    query

preloadCardNames()

collectSummaryCounters = ->
    redisCounterData = {}
    for period in config.task.time
        period_name = PERIOD_NAMES[period]
        redisCounterData[period_name] = {}
        for source in config.task.source
            redisCounterData[period_name][source] = await redis.load 'count', source, period
    new Promise (resolve, reject) -> 
        redis.client.set COUNTER_SUMMARY_NAME, JSON.stringify(redisCounterData), (err, reply) -> resolve(reply)

getSummaryCounters = ->
    new Promise (resolve, reject) ->
        redis.client.get COUNTER_SUMMARY_NAME, (err, reply) ->
            if err then reject err else resolve reply

module.exports.addCardName = addCardName
module.exports.collectSummaryCounters = collectSummaryCounters
module.exports.getSummaryCounters = getSummaryCounters
pg = require 'pg'
moment = require 'moment'
middleware = require './middlewares'
config = require './config.json'

task = config.task
list = config.listTime
pool = new pg.Pool config.pg

PG_QUERY_SINGLE_SQL = "SELECT id, category, source, sum(frequency) frequency, sum(numbers) numbers, sum(putone) putone, sum(puttwo) puttwo, sum(putthree) putthree, sum(putoverthree) putoverthree from single_day WHERE time >= $1::Date and time < $2::Date and category = $3::varchar and source = $4::varchar GROUP BY (id, category, source) ORDER BY sum(frequency) DESC LIMIT 100"
PG_QUERY_DECK_SQL = "SELECT name, source, sum(count) count from deck_day WHERE time >= $1::Date and time < $2::Date and source = $3::varchar GROUP BY name, source ORDER BY sum(count) DESC LIMIT 100"
PG_QUERY_COUNT_SQL = "SELECT count from counter WHERE time = $1::Date and timeperiod = $2::integer and source = $3::varchar"
PG_QUERY_TAG_SQL = "SELECT name, source, sum(count) count from tag_day where time >= $1::Date and time < $2::Date and name like $3::varchar and source = $4::varchar GROUP BY name, source ORDER BY sum(count) DESC LIMIT 3"

formatTime = (moment) -> moment.format("YYYY-MM-DD")
calculateTime = (period) ->
  now = moment()
  if period < 0
    listTimes = list.map (str) -> moment(str, 'MM-DD')
    lastTime = listTimes[0]
    for time in listTimes
      if time.isSameOrAfter now
        return [formatTime(lastTime), formatTime(now.subtract 1, 'days')]
    lastTime = time
  else if period == 0
    [formatTime(now), formatTime(moment(now).add 1, 'days')]
  else
    [formatTime(moment(now).subtract period, 'days'), formatTime(now)]

queryNamedTable = (name, startTime, endTime, source, period) ->
  switch name
    when 'deck'
      promise = pool.query PG_QUERY_DECK_SQL, [startTime, endTime, source]
      return promise.then (result) => queryNamedTag result.rows, startTime, endTime, source
    when 'count'
      period = if period < 0 then 0 else period
      return pool.query PG_QUERY_COUNT_SQL, [endTime, period, source]
    when 'single'
      return Promise.all ['monster', 'spell', 'trap', 'side', 'ex'].map (category) -> pool.query(PG_QUERY_SINGLE_SQL, [startTime, endTime, category, source]).then middleware.addCardName
  null

queryNamedTag = (datas, startTime, endTime, source) ->
  Promise.all datas.map (data) ->
    pool.query(PG_QUERY_TAG_SQL, [startTime, endTime, "#{data.name}-%", source]).then (tags) ->
      data.tags = tags.rows.map (tag) => tag.name
      data

module.exports.query = ->
  for source from task.source
    source = source.replace /entertain(?!ment)/, 'entertainment'
    for period from task.time
      [startTime, endTime] = calculateTime period
      promises = task.table.map (table) => queryNamedTable table, startTime, endTime, source, period
      yield {
        source: source
        period: period
        startTime: startTime
        endTime: endTime
        promise: Promise.all(promises)
      }
  0

module.exports.setConfig = (target) ->
  config = target
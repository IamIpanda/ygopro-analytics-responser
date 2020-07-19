pg = require 'pg'
moment = require 'moment'
middleware = require './middlewares'
config = require './config.json'

task = config.task
list = config.listTime
pool = new pg.Pool config.pg

PG_QUERY_SINGLE_SQL = "SELECT id, max(time) recent_time, category, source, sum(frequency) frequency, sum(numbers) numbers, sum(putone) putone, sum(puttwo) puttwo, sum(putthree) putthree, sum(putoverthree) putoverthree from single WHERE time >= $1::Date and time < $2::Date and category = $3::varchar and source = $4::varchar GROUP BY (id, category, source) ORDER BY sum(frequency) DESC LIMIT 100"
PG_QUERY_DECK_SQL = "SELECT name, max(time) recent_time, source, sum(count) count from deck WHERE time >= $1::Date and time < $2::Date and source = $3::varchar GROUP BY name, source ORDER BY sum(count) DESC LIMIT 100"
PG_QUERY_COUNT_SQL = "SELECT count from count WHERE time = $1::Date and timeperiod = $2::integer and source = $3::varchar"
PG_QUERY_TAG_SQL = "SELECT name, source, sum(count) count from tag where time >= $1::Date and time < $2::Date and name like $3::varchar and source = $4::varchar GROUP BY name, source ORDER BY sum(count) DESC LIMIT 3"
PG_QUERY_MATCHUP_FIRST_SQL  = "select decka, sum(win) win, sum(draw) draw, sum(lose) lose from matchup where source = $1::varchar and period = $2::varchar and decka = $3::varchar group by decka;"
PG_QUERY_MATCHUP_SECOND_SQL = "select deckb, sum(win) win, sum(draw) draw, sum(lose) lose from matchup where source = $1::varchar and period = $2::varchar and deckb = $3::varchar group by deckb;"
PG_QUERY_MATCHUP_DETAIL_SQL = "select decka, deckb, win, draw, lose from matchup where source = $1::varchar and period = $2::varchar and decka in $3 and deckb in $3"

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
      return promise.then (result) => await queryNamedTag result.rows, startTime, endTime, source; result
                    .then (result) => await queryMatchup  result.rows, source
    when 'count'
      period = if period < 0 then 0 else period
      return pool.query PG_QUERY_COUNT_SQL, [startTime, period, source]
    when 'single'
      return Promise.all ['monster', 'spell', 'trap', 'side', 'ex'].map (category) -> pool.query(PG_QUERY_SINGLE_SQL, [startTime, endTime, category, source]).then middleware.addCardName
    when 'matchup'
      return null unless source == 'mycard-athletic' || source == 'mycard-entertain'
      return null unless period == 1
      decks = await pool.query PG_QUERY_DECK_SQL, [startTime, endTime, source]
      names = decks.rows.map((data) => data.name).slice 0, 10
      name_description = "('" + names.join("','") + "')"
      return pool.query PG_QUERY_MATCHUP_DETAIL_SQL.replace("$3", name_description).replace("$3", name_description), [source.slice(7), moment().format('YYYY-MM')]
  null

queryNamedTag = (datas, startTime, endTime, source) ->
  await Promise.all datas.map (data) ->
    pool.query(PG_QUERY_TAG_SQL, [startTime, endTime, "#{data.name}-%", source]).then (tags) ->
      data.tags = tags.rows.map (tag) => tag.name
      data

queryMatchup = (datas, source) ->
  return datas unless source == 'mycard-athletic' || source == 'mycard-entertain'
  source = source.slice 7
  period = moment().format('YYYY-MM')
  await Promise.all datas.map (data) ->
    data.matchup =
      first:  null
      second: null
    await pool.query(PG_QUERY_MATCHUP_FIRST_SQL,  [source, period, data.name]).then (matchup) ->
      data.matchup.first = matchup.rows[0]
    await pool.query(PG_QUERY_MATCHUP_SECOND_SQL, [source, period, data.name]).then (matchup) ->
      data.matchup.second = matchup.rows[0]
    data

module.exports.query = ->
  for source from task.source
    #source = source.replace /entertain(?!ment)/, 'entertainment'
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

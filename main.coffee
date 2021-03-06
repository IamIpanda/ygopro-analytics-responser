server = require './server'
watcher = require './watcher'
schedule = require 'node-schedule'
config = require './config.json'

args = process.argv
server(9999) if args.indexOf("--server") > 0
watcher() if args.indexOf("--exec") > 0
schedule.scheduleJob config.schedule, -> watcher() if args.indexOf("--watch") > 0

module.exports.server = server
module.exports.watcher = watcher
module.exports.router = require './router'
module.exports.setConfig = require('./pg').setConfig
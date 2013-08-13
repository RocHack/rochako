#!/usr/bin/env coffee
# rochako.coffee - IRC Bot for RocHack, with Markov chains and stuff

bot = require './bot'

config = require './config'
couch = config.couch
debug = config.debug
useTumblr = config.tumblr.host and config.tumblr.key and yes

designDocUrl = couch.db + '/_design/couchgrams/'

delimiter = /\s+/
n = 3
maxWords = 30
live = process.argv.length <= 2 && process.argv[2] != '-'

nicksByChannel = {}
nicksInChannels = {}
badWordRetryLimit = 1

if live
  bot = new Bot(config)

# look up a karma value
getKarma = (name, cb) ->
  request.get designDocUrl + '_rewrite/karma/' + name, (error, resp, body) ->
    cb +body || 0

unknownCommand = (args, from, channel) ->
  client.say channel, 'Unknown command ' + args[0]

#!/usr/bin/env coffee
# rochako.coffee - IRC Bot for RocHack, with Markov chains and stuff

{Bot} = require './bot'
services = require './services'

config = require './config'
couch = config.couch
debug = config.debug
useTumblr = config.tumblr.host and config.tumblr.key and yes

useStdin = process.argv[2] == '-'

if useStdin
  config.irc = null
  config.api = null
  config.cli = true

bot = new Bot(config)

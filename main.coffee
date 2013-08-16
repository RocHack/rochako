#!/usr/bin/env coffee
# rochako.coffee - IRC Bot for RocHack, with Markov chains and stuff

{Bot} = require './bot'
services = require './services'

config = require './config'
couch = config.couch
debug = config.debug
useTumblr = config.tumblr.host and config.tumblr.key and yes

live = process.argv.length <= 2 && process.argv[2] != '-'
useStdin = !live && process.argv[2] == '-'

if !live
  config.irc = null
  if useStdin
    config.repl = process
  else
    config.cli = {useStdin, process}

bot = new Bot(config)

{EventEmitter} = require 'events'

class @CLIService extends EventEmitter

  constructor: (bot) ->
    input = process.argv.slice(2).join(' ')
    bot.generateResponse input, (response) ->
      console.log response
      process.exit 0

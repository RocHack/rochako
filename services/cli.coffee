{EventEmitter} = require 'events'

class @CLIService extends EventEmitter

  constructor: (process) ->
    input = process.argv.slice(2).join(' ')
    @emit 'pm', null, input

  send: (t, sentence) ->
    console.log sentence
    process.exit 0

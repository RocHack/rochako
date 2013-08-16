{EventEmitter} = require 'events'
readline = require 'readline'

class @REPLService extends EventEmitter

  prompt: '> '

  constructor: ({stdin, stdout}) ->
    @rl = readline.createInterface stdin, stdout
    @question()

  question: =>
    @rl.question @prompt, (input) =>
      @emit 'pm', null, input

  send: (to, sentence) ->
    console.log sentence
    #stdout.write sentence
    @question()

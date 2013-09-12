{EventEmitter} = require 'events'
readline = require 'readline'

class @REPLService extends EventEmitter

  prompt: ''

  constructor: (@bot) ->
    @rl = readline.createInterface process.stdin, process.stdout
    @question()

  question: =>
    @rl.question @prompt, @generateResponse

  generateResponse: (input) =>
    @bot.generateResponse input, @respond

  respond: (response) =>
    console.log response
    @question()

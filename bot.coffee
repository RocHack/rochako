{ConversationEngine} = require './conversation'
services = require './services'
commands = require './commands'

unknownCommand = (args, service, from, channel) ->
  service.say channel, 'Unknown command ' + args[0]

class @Bot

  constructor: (@config) ->
    @conversations = new ConversationEngine
      bot: this
      db: @config.couch.db
      prefix: []
      debug: @config.debug

    @commands = {}
    commands.register this

    @services = []

    for own name, Service of services
      if conf = @config[name]
        @services.push new Service this, conf

  registerCommand: (name, fn) ->
    @commands[name] = fn

  executeCommand: (args, service, from, channel) ->
    fn = @commands[args[0]] or commands.unknown
    fn.call this, args, service, from, channel

  generateResponse: (message, cb) ->
    @conversations.generateResponse message, cb

  log: (message, sender, channel) ->
    @conversations.picker.log message, sender, channel

  isBadNgram: (ngram) ->
    @services.some (service) ->
      service.isBadNgram? ngram

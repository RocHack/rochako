{ConversationEngine} = require './conversation'
{merge} = require './util'
services = require './services'
commands = require './commands'
clonebot = require './clonebot'

class @Bot

  constructor: (@config) ->
    @conversations = new ConversationEngine
      bot: this
      db: @config.couch.db
      sender: @config.imitate
      debug: @config.debug
      skiplog: @config.skiplog

    @commands = {}
    commands.register this

    @services = []
    @clones = []

    for own name, Service of services
      if conf = @config[name]
        @services.push new Service this, merge conf,
          debug: @config.debug

  # disconnect all services and clones
  quit: (reason) ->
    @services.concat(@clones).forEach (thing) ->
      thing.quit reason

  registerCommand: (name, fn, isEffective) ->
    @commands[name] = fn
    fn.isEffective = isEffective or -> true

  executeCommand: (args, service, from, channel) ->
    fn = @commands[args[0]] or commands.unknown
    if fn.isEffective and !fn.isEffective.call @, service, channel
      fn = commands.denied
    fn.call this, args, service, from, channel

  effectiveCommands: (service, channel) ->
    name for own name, cmd of @commands when\
      cmd.isEffective.call @, service, channel

  generateResponse: (message, cb) ->
    @conversations.generateResponse message, cb

  imitateResponse: (message, imitate, cb) ->
    if imitate
      conv = @conversations.clone imitate
      conv.generateResponse message, cb
    else
      @generateResponse message, cb

  log: (message, sender, channel) ->
    @conversations.picker.log message, sender, channel

  isBadNgram: (ngram) ->
    @services.some (service) ->
      service.isBadNgram? ngram

  # spawn a markov clone bot using a nick's messages as corpus
  spawnClone: (service, channel, targetNick) ->
    parentConfig = @config
    @clones.push new CloneBot {parentConfig, targetNick, channel, service}

CloneBot = clonebot.factory @Bot

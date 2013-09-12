irc = require 'irc'
{merge} = require '../util'

delimiter = /\s+/

class @IRCMultiService

  constructor: (bot, options) ->
    {@nick, @servers} = options
    @clients =
      for server in @servers
        new IRCService bot, merge options, server

  quit: (msg) ->
    @clients.forEach (client) ->
      client.quit msg

class IRCService

  constructor: (@bot, @options) ->
    @sentTopic = {}
    @nicksByChannel = {}
    @nicksInChannels = {}

    {@nick, @nickServPassword, @address} = @options
    {@chattiness, @polite, @debug} = @options
    @client = new irc.Client @address, @nick, @options

    @selfPingRegex = new RegExp "^#{@nick}: "
    @selfStartRegex = new RegExp "^#{@nick} "
    @commandRegex = new RegExp "^#{@nick}:?\\s*/(.*)$"
    #@selfDoubleStartRegex = new RegExp "^#{@nick} #{@nick} "

    for own event, handler of @events
      @client.on event, handler.bind @

  quit: (msg) ->
    @client.disconnect msg

  events:

    connect: ->
      console.log "connected to #{@address}"
      if password = @nickServPassword
        console.log 'identifying to NickServ'
        @say 'NickServ', 'identify ' + password

    # log and respond to messages in the channels
    message: (from, channel, message) ->
      if from == @nick
        # don't respond to self
        console.log 'skipping own message'
        return

      if m = message.match @commandRegex
        args = m[1].split delimiter
        @bot.executeCommand args, this, from, channel
        return

      # don't log commands
      else
        # log the received message
        @log message, from, channel

      # speak only when spoken to, or when the spirit moves me --coleifer
      addressed = (message.indexOf @nick) != -1

      if addressed or Math.random() < @chattiness
        @respondTo message, channel

    # respond to /me actions
    action: (from, chan, message) ->
      addressed = (message.indexOf @nick) != -1

      # include the name
      msg = '/me ' + message
      msg2 = from + ' ' + message

      if addressed or Math.random() < @chattiness
        @respondTo msg2, chan

      # log the received message
      @log msg, from, chan

    # log topics, but not initial topic
    topic: (chan, topic, nick, msg) ->
      if @sentTopic[chan]
        @log topic, chan, chan
        if @debug
          console.log 'topic for unknown channel', chan
      else
        @sentTopic[chan] = true

    # respond to PMs
    pm: (from, message) ->
      if from == 'NickServ'
        console.log 'NickServ:', message
      else
        @respondTo message, from

    # keep track of nicks in channels
    names: (channel, nicks) ->
      @nicksByChannel[channel] ||= {}
      for nick of nicks
        nick = nick.toLowerCase()
        @nicksInChannels[nick] = true
        @nicksByChannel[channel][nick] = true

    join: (channel, nick, message) ->
      @nicksByChannel[channel] ||= {}
      @nicksByChannel[channel][nick] = true
      nick = nick.toLowerCase()
      @nicksInChannels[nick] = true

    nick: (oldnick, newnick, channels, message) ->
      oldnick = oldnick.toLowerCase()
      newnick = newnick.toLowerCase()
      for channel in channels
        @nicksByChannel[channel] ||= {}
        delete @nicksByChannel[channel][oldnick]
        delete @nicksInChannels[oldnick]
        @nicksByChannel[channel][newnick] = true
        @nicksInChannels[newnick] = true

    part: (channel, nick, reason, message) ->
      nick = nick.toLowerCase()
      delete @nicksByChannel[channel][nick] if channel of @nicksByChannel
      delete @nicksInChannels[nick]

    quit: (nick, reason, channels, message) ->
      nick = nick.toLowerCase()
      for channel in channels
        delete @nicksByChannel[channel][nick] if channel of @nicksByChannel
        delete @nicksInChannels[nick]

    # log client errors
    error: (msg) ->
      if msg == 'err_bannedfromchan'
        channel = msg.args[1]
        console.error "banned from #{channel}!"
      else
        console.error 'error:', msg.command, msg.args.join ' '

    # stop the script we if can't reconnect.
    abort: (n) ->
      console.error 'aborted after', n, 'retries.'
      #process.exit 1

    # extra debuggery
    raw: (n) ->
      if @debug > 1
        console.log 'RAW', n

  log: (message, sender, channel) ->
    @bot.log message, sender, channel

  # generate and send a message in response to a message received
  respondTo: (message, sender) ->
    if @debug then console.log '-->', message
    @bot.generateResponse message, (response) =>
      # don't talk to self
      if 0 == response.indexOf "#{@nick}: "
        console.log 'removing self address'
        response = response.replace @selfPingRegex, ''

      # use /me instead of naming self
      else if 0 == response.indexOf "#{@nick} "
        # unless it's doing a pokemon
        if 0 != response.indexOf "#{@nick} #{@nick}"
          action = response.replace @selfStartRegex, ''

      # send message
      if action
        @client.action sender, action
      else
        @say sender, response

      # log own message
      @bot.log response, @nick, sender if response

      if @debug then console.log '<--', response

  say: (to, message) ->
    @client.say to, message

  isBadWord: (word, channel) =>
    if @badWords[word] or @nicksInChannels[word] then return yes
    word = word.toLowerCase()
    for badWord of @badWords
      return yes if -1 != word.indexOf badWord
    for nick of @nicksInChannels
      return yes if -1 != word.indexOf nick

  isBadNgram: (ngram) ->
    @polite and ngram.some @isBadWord

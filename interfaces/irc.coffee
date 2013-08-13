irc = require 'irc'

debug = false

myNick = config.irc.nick
server = config.irc.server
chattiness = config.irc.chattiness

client = new irc.Client server, myNick, config.irc

client.on 'connect', ->
  console.log "connected to #{server}"
  password = config.irc.nickServPassword
  if password
    console.log 'identifying to NickServ'
    client.say 'NickServ', 'identify ' + password

# log and respond to messages in the channels
client.on 'message', (from, channel, message) ->
  if from == myNick
    # don't respond to self
    console.log 'skipping own message'
    return

  if m = message.match commandRegex
    args = m[1].split delimiter
    console.log 'possible command', args
    fn = commands[args[0]] or unknownCommand
    fn args, from, channel
    return

  # don't log commands
  else
    # log the received message
    log message, from, channel

  # speak only when spoken to, or when the spirit moves me -coleifer
  addressed = (message.indexOf myNick) != -1

  if addressed or Math.random() < chattiness
    respondTo message, channel

# respond to /me actions
client.on 'action', (from, chan, message) ->
  addressed = (message.indexOf myNick) != -1

  # include the name
  msg = '/me ' + message
  msg2 = from + ' ' + message

  if addressed or Math.random() < chattiness
    respondTo msg2, chan

  # log the received message
  log msg, from, chan

# log topics, but not initial topic
sentTopic = {}
client.on 'topic', (chan, topic, nick, msg) ->
  if !sentTopic[chan]
    sentTopic[chan] = true
  else
    log topic, chan, chan
    if debug
      console.log 'topic for unknown channel', chan

# respond to PMs
client.on 'pm', (from, message) ->
  if from == 'NickServ'
    console.log 'NickServ:', message
  else
    respondTo message, from

# keep track of nicks in channels
client.on 'names', (channel, nicks) ->
  nicksByChannel[channel] ||= {}
  for nick of nicks
    nicksInChannels[nick] = true
    nicksByChannel[channel][nick] = true

client.on 'join', (channel, nick, message) ->
  nicksByChannel[channel] ||= {}
  nicksByChannel[channel][nick] = true
  nicksInChannels[nick] = true

client.on 'nick', (oldnick, newnick, channels, message) ->
  channels.forEach (channel) ->
    nicksByChannel[channel] ||= {}
    delete nicksByChannel[channel][oldnick]
    delete nicksInChannels[oldnick]
    nicksByChannel[channel][newnick] = true
    nicksInChannels[newnick] = true

client.on 'part', (channel, nick, reason, message) ->
  delete nicksByChannel[channel][nick] if channel of nicksByChannel
  delete nicksInChannels[nick]

client.on 'quit', (nick, reason, channels, message) ->
  channels.forEach (channel) ->
    delete nicksByChannel[channel][nick] if channel of nicksByChannel
    delete nicksInChannels[nick]

# log client errors
client.on 'error', (msg) ->
  if msg == 'err_bannedfromchan'
    channel = msg.args[1]
    console.error "banned from #{channel}!"

  console.error 'error:', msg.command, msg.args.join ' '

# stop the script we if can't reconnect.
client.on 'abort', (n) ->
  console.error 'aborted after', n, 'retries.'
  #process.exit 1

# extra debuggery
if debug > 1
  client.on 'raw', (n) ->
    console.log 'RAW', n


#!/usr/bin/env coffee
# rochako.coffee - IRC Bot for RocHack, with Markov chains and stuff

request = require 'request'
{Tumblr} = require 'tumblr'

config = require './config'
couch = config.couch
debug = config.debug
myNick = config.irc.nick
server = config.irc.server
chattiness = config.irc.chattiness
polite = config.irc.polite
useTumblr = config.tumblr.host and config.tumblr.key and yes

designDocUrl = couch.db + '/_design/couchgrams/'

delimiter = /\s+/
n = 3
maxWords = 30
live = process.argv.length <= 2 && process.argv[2] != '-'

useStdin = !live && process.argv[2] == '-'

badWordRetryLimit = 1
nicksByChannel = {}
nicksInChannels = {}
badWords = # lowercase
  chimeracoder: true

# todo: generate a regexes of bad words
isBadWord = (word) ->
  #if word == myNick then return no
  if badWords[word] or nicksInChannels[word] then return yes
  word = word.toLowerCase()
  for badWord of badWords
    return yes if -1 != word.indexOf badWord
  for nick of nicksInChannels
    return yes if -1 != word.indexOf nick.toLowerCase()

isBadNgram = (ngram) ->
  polite and ngram.some isBadWord

zeropad = (n) -> ('00' + n).substr(-1)
spacepad = (str) -> ('                ' + str).substr(-16)

docsToHTML = (docs) ->
  inner = docs.map (doc) ->
    d = new Date doc._id
    zeropad(d.getHours()) + ':' + zeropad(d.getMinutes()) +
      doc.sender + ' | ' + doc.text
      #chunk(doc.text).join('                      | ')
  .join '<br>\n'
  "<pre>#{inner.replace /</g, '&lt;'}</pre>"

postDocsToTumblr = (docs, cb) ->
  return cb no unless useTumblr
  request.post
    url: "https://api.tumblr.com/v2/blog/#{config.tumblr.host}/post"
    body:
      api_key: config.tumblr.key
      type: 'text'
      body: docsToHTML docs
  , (error, resp, body) ->
    if error or resp?.statusCode != 201
      cb false
    else
      url = resp.headers?['Location']
      cb url or try JSON.stringify resp

if live
  irc = require 'irc'
  client = new irc.Client server, myNick, config.irc

wordsContains = (words, allWords) ->
  -1 != (allWords.join ' ').indexOf words.join ' '

# generate a response message to a given message
generateResponse = (seedMessage, cb) ->
  words = seedMessage.split delimiter
  generateResponseSequence words, n, (sequence) ->
    sentence = sequence.join ' '
    cb sentence

# Generate sequences starting from the n-grams in the given words
# and pick the longest sequence.
# wordN is the length of the ngrams to group the seed words into
generateResponseSequence = (words, wordN, cb) ->
  # get n-grams in seed message
  #console.log m, wordN, seedNgrams, words
  if wordN <= 0
    #console.log 'a'
    # worse case: just start with a blank (random) prefix
    return generateSequence n, [], maxWords, cb
  else if wordN == 1
    #console.log 'b'
    seedNgrams = ([word] for word in words)
  else
    m = wordN-2
    seedNgrams = (words[i..i+m] for a, i in words when i+m < words.length)
    if !seedNgrams.length
      #console.log 'c'
      return generateResponseSequence words, wordN-1, cb

  # generate sequences from each ngram
  sequences = []
  seedNgrams.forEach (ngram) ->
    #console.log 'asf', ngram
    generateSequence n, ngram, maxWords, (seq) ->
      # maybe include last word of initial ngram
      if seq.length and Math.random() < .25
        seq.unshift ngram.pop()
      # this sentence is a possible option
      sequences.push seq
      if sequences.length == seedNgrams.length
        #console.log sequences.map (sen) -> sen.join ' '
        # convert longest sequence into a string and return it
        longest = sequences.reduce (a, b) ->
          if b.length > a.length then b else a
        #console.log ':', longest, words
        if longest.length == 0 or wordsContains longest, words
          # try smaller seed word groupings if the message is empty
          # or a copy of the seed meessage
          #console.log 'trying smaller wordlength', wordN
          generateResponseSequence words, wordN-1, cb
        else
          # use this sequence
          cb longest

# Generate a Markov chain starting with the words in prefix
generateSequence = (n, prefix, maxlen, cb, retries) ->
  if maxlen == 0 then return cb []
  getNgram n, prefix, (ngram) ->
    if ngram == null
      cb []
    else
      if isBadNgram ngram
        retries |= 0
        if retries < badWordRetryLimit
          console.log 'try to find a better ngram', retries
          # try to find a better ngram
          generateSequence n, prefix, maxlen, cb, retries+1
        else
          # give up
          console.log 'give up', retries
          cb []
      else
        newWords = ngram[prefix.length..]
        nextPrefix = ngram[1-n..]
        # empty string in the ngram means end of line
        #console.log 'pref', nextPrefix, newWords, n, ngram
        if ngram[n-1] == ''
          while newWords[newWords.length-1] == ''
            newWords.pop()
          cb newWords
        else
          generateSequence n, nextPrefix, maxlen-1, (tail) ->
            cb newWords.concat tail

getNgram = (n, seed, cb) ->
  # n should be 3, maybe 2. couchgrams is too slow for 1 currently
  if n <= 1
    return cb ['fail']
  # alternate method is faster when there are more ngrams
  if n < 4
    return getNgram2 n, seed, cb
  # seed should be an array of length < n
  # cb will be called with an array prefixed by seed
  request.get
    url: designDocUrl + '_list/pick_ngram/ngrams'
    qs:
      non_empty: true
      group_level: n
      startkey: JSON.stringify seed
      endkey: JSON.stringify seed.concat {}
    json: true
  , (error, resp, ngram) ->
    if resp?.statusCode != 200
      console.error 'failed to get ngram:', seed, error || resp?.statusCode, ngram
      return
    if ngram and !ngram.slice then ngram = []
    if debug then console.log (seed.join ' '), '-->', ngram?.join ' '
    cb ngram

getNgram2 = (n, seed, cb) ->
  # seed should be an array of length < n
  # cb will be called with an array prefixed by seed
  startkey = JSON.stringify seed
  endkey = JSON.stringify seed.concat {}
  request.get
    url: url = designDocUrl + '_view/ngrams'
    qs: qs = {startkey, endkey}
    json: true
  , (error, resp, body) ->
    if resp?.statusCode != 200
      console.error 'failed to get ngram:', seed, error || resp?.statusCode, url, qs, body
      return

    max = body?.rows[0]?.value
    if !max
      #console.log 'no results for', seed, startkey, endkey
      return cb null
    index = Math.ceil max * Math.random()

    # Optimization: if the index is in the second half, reverse the
    # rows and iterate less
    if descending = index > max/2
      [startkey, endkey] = [endkey, startkey]
      index = max - index

    request.get
      url: designDocUrl + '_list/pick_ngram/ngrams'
      qs:
        descending: descending
        i: index
        group_level: n
        startkey: startkey
        endkey: endkey
      json: true
    , (error, resp, ngram) ->
      if resp?.statusCode != 200
        console.error 'failed to get ngram:', seed, error || resp?.statusCode, ngram
        return
      if ngram and !ngram.slice then ngram = []
      if debug then console.log (seed.join ' '), '-->', ngram?.join ' '
      cb ngram

# look up a karma value
getKarma = (name, cb) ->
  request.get designDocUrl + '_rewrite/karma/' + name, (error, resp, body) ->
    cb +body || 0

selfPingRegex = new RegExp "^#{myNick}: "
selfStartRegex = new RegExp "^#{myNick} "
selfDoubleStartRegex = new RegExp "^#{myNick} #{myNick} "

# generate and send a message in response to a message received
respondTo = (message, sender) ->
  if debug then console.log '-->', message
  generateResponse message, (response) ->
    # don't talk to self
    if 0 == response.indexOf "#{myNick}: "
      console.log 'removing self address'
      response = response.replace selfPingRegex, ''

    # use /me instead of naming self
    else if 0 == response.indexOf "#{myNick} "
      # unless it's doing a pokemon
      if 0 != response.indexOf "#{myNick} #{myNick}"
        response = response.replace selfStartRegex, ''
        isAction = true

    # send message
    if isAction
      client.action sender, response
    else
      client.say sender, response

    # log own message
    log response, myNick, sender if response

    if debug then console.log '<--', response

# log a message
log = (message, sender, channel) ->
  if debug
    console.log 'logging:', message
  data =
    text: message
    sender: sender
    channel: channel
  request.put
    url: url = designDocUrl + '_update/add_text'
    json: data
  , (error, resp, body) ->
    if body != 'ok'
      console.error 'failed to log: ', url, data, resp?.statusCode, error || body

# for a test run, generate a response and exit.
if !live
  if useStdin
    readline = require 'readline'
    rl = readline.createInterface process.stdin, process.stdout
    question = ->
      rl.question '> ', (input) ->
        generateResponse input, (sentence) ->
          console.log sentence
          question()
    question()
    return

  else
    input = process.argv.slice(2).join(' ')
    generateResponse input, (sentence) ->
      console.log sentence
      process.exit 0
  return

# after this point assumes live mode.

commandRegex = new RegExp "^#{myNick}:?\s*/(.*)$"

commands =
  _unknown: (args, from, channel) ->
    client.say channel, 'Unknown command ' + args[0]

  help: (args, from, channel) ->
    cmds = (name for own name of commands).join ', '
    client.say channel, 'Commands: ' + cmds

  karma: (args, from, channel) ->
    if name = args[1]
      getKarma name, (karma) ->
        client.say channel, name + ': ' + karma

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
    fn = commands[args[0]] or commands._unknown
    fn args, from, channel

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
  process.exit 1

# extra debuggery
if debug > 1
  client.on 'raw', (n) ->
    console.log 'RAW', n

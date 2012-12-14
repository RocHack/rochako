#!/usr/bin/env coffee
# rochako.coffee - IRC Bot for RocHack, with Markov chains and stuff

nick = 'rochako'
server = 'asimov.freenode.net'
channel = '##rochack'
chattiness = 0.001
password = '************'

couch = (require './cred').couch
delimiter = /\s+/
n = 3
maxWords = 30
live = process.argv.length <= 2 && process.argv[2] != '-'
debug = false

useStdin = !live && process.argv[2] == '-'

if live
  irc = require 'irc'
  client = new irc.Client server, nick,
    userName: 'rochako'
    realName: 'Rochako IRC Bot'
    channels: [channel]
    secure: true
    port: 6697

httpS = require if couch.secure then 'https' else 'http'

request = (method, path, body, cb) ->
  returned = false
  # only call cb once
  cb2 = (body) ->
    cb body if !returned
    returned = true
  opt =
    method: method or 'GET'
    path: '/' + couch.database + '/_design/couchgrams/' + path
  opt[k] = v for k, v of couch
  req = httpS.request opt, (res) ->
    data = ''
    res.on 'data', (chunk) ->
      data += chunk
    res.on 'end', ->
      cb2 data
  req.on 'error', (e) ->
    cb2 null
  req.end(body or null)

fetch = (path, cb) ->
  request 'GET', path, null, cb

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
generateSequence = (n, prefix, maxlen, cb) ->
  if maxlen == 0 then return cb []
  getNgram n, prefix, (ngram) ->
    if ngram == null
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
  # seed should be an array of length < n
  # cb will be called with an array prefixed by seed
  startkey = encodeURIComponent JSON.stringify seed
  endkey = encodeURIComponent JSON.stringify seed.concat {}
  url = '_list/pick_ngram/ngrams?nonempty&group_level=' + n +
    '&startkey=' + startkey + '&endkey=' + endkey
  fetch url, (res) ->
    ngram = try JSON.parse res
    if ngram and !ngram.slice then ngram = []
    if debug then console.log (seed.join ' '), '-->', ngram?.join ' '
    cb ngram

# look up a karma value
getKarma = (name, cb) ->
  fetch '_rewrite/karma/' + name, (res) ->
    cb +res || 0

selfPingRegex = new RegExp "^#{nick}: "

# generate and send a message in response to a message received
respondTo = (message, sender) ->
  if debug then console.log '-->', message
  generateResponse message, (response) ->
    # don't talk to self
    if 0 == response.indexOf nick
      log 'removing self address'
      response = response.replace selfPingRegex, ''

    # send message
    client.say sender, response

    # log own messages if in channel
    log response if sender == channel
    if debug then console.log '<--', response

# log a message
log = (message) ->
  if debug
    console.log 'logging:', message
  request 'PUT', '_update/add_text', message, (res) ->
    if res != 'ok'
      console.error 'failed to log: ', message, res

# for a test run, generate a response and exit.
if !live
  if useStdin
    readline = require 'readline'
    rl = readline.createInterface process.stdin, process.stdout
    rl.question '', (input) ->
      generateResponse input, (sentence) ->
        console.log sentence
        process.exit 0
    return

  else
    input = process.argv.slice(2).join(' ')
    generateResponse input, (sentence) ->
      console.log sentence
      process.exit 0
  return

# after this point assumes live mode.

client.on 'connect', ->
  console.log "connected to #{server}g"
  if password
    console.log 'identifying to NickServ'
    client.say 'NickServ', 'identify ' + password

# respond to and log messages in the channel
client.on "message#{channel}", (from, message) ->
  # log the received message
  log message

  # do karma duty
  if 0 == message.indexOf 'karmo '
    name = (message.split delimiter)[1]
    if name
      getKarma name, (karma) ->
        # karma response is not getting logged
        client.say channel, name + ': ' + karma
      return

  # speak only when spoken to, or when the spirit moves me -coleifer
  addressed = (message.indexOf nick) != -1

  if addressed or Math.random() < chattiness
    respondTo message, channel

# respond to /me actions
client.on 'action', (from, chan, message) ->
  addressed = (message.indexOf nick) != -1

  # include the name
  msg = '/me ' + message
  msg2 = from + ' ' + message

  if addressed or Math.random() < chattiness
    respondTo msg2, chan

  # log the received message
  log msg

# log topics, but not initial topic
initialTopic = true
client.on 'topic', (chan, topic, nick, msg) ->
  if initialTopic
    initialTopic = false
  else if chan == channel
    log topic
  else if debug
    console.log 'topic for unknown channel', chan

# respond to PMs
client.on 'pm', (from, message) ->
  if from == 'NickServ'
    console.log 'NickServ:', message
  else
    respondTo message, from

# log client errors
client.on 'error', (msg) ->
  console.error 'error:', msg.command, msg.args.join ' '

# stop the script we if can't reconnect.
client.on 'abort', (n) ->
  console.error 'aborted after', n, 'retries.'
  process.exit 1

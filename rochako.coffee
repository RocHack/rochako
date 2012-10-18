#!/usr/bin/env coffee
# rochako.coffee - IRC Bot for RocHack, with Markov chains and stuff

nick = 'rochako'
server = 'hubbard.freenode.net'
channel = '##rochack'
chattiness = 0.004

couchDB = 'http://localhost:5984/ircmarkov'
delimiter = /\s/
n = 3
maxWords = 30
live = true

irc = require 'irc'
if live then client = new irc.Client server, nick,
  userName: 'rochako'
  realName: 'Rochako IRC Bot'
  channels: [channel]

http = require 'http'
fetch = (url, cb) ->
  http.get url, (res) ->
    data = ''
    res.on 'data', (chunk) ->
      data += chunk
    res.on 'end', ->
      cb data

      ###
arraysEqual = (arr1, arr2) ->
  arr1.length == arr2.length and
    arr1.every (item, i) -> arr2[i] == item
    ###

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
  url = couchDB +
    '/_design/couchgrams/_list/pick_ngram/ngrams?nonempty&group_level=' + n +
    '&startkey=' + startkey + '&endkey=' + endkey
  fetch url, (res) ->
    ngram = try JSON.parse res
    if ngram and !ngram.slice then ngram = []
    console.log (seed.join ' '), '-->', ngram?.join ' '
    cb ngram
  .on 'error', (e) ->
    console.error 'Error looking up word. ' + e.message
    cb null

respondTo = (message, sender) ->
  console.log '-->', message
  generateResponse message, (response) ->
    client.say sender, response
    console.log '<--', response

client?.addListener "message#{channel}", (from, message) ->
  # speak only when spoken to, or when the spirit moves me -coleifer
  addressed = (message.indexOf nick) != -1

  if addressed or Math.random() < chattiness
    respondTo message, channel

#client.addListener 'pm', (from, message) ->
  #console.log "pm from #{from}: #{message}"

if !live
  input = process.argv.slice(2).join(' ')
  generateResponse input, (sentence) ->
    console.log '-->', sentence

{NgramPicker} = require './ngrams'
{merge} = require './util'

wordsContains = (words, allWords) ->
  -1 != (allWords.join ' ').indexOf words.join ' '

delimiter = /\s+/
n = 3
maxWords = 30

class @ConversationEngine

  constructor: (@options) ->
    {@bot} = @options
    @picker = new NgramPicker @options
    @badWordRetryLimit = 1

  clone: (imitate) ->
    new @constructor merge @options, sender: imitate

  # generate a response message to a given message
  generateResponse: (seedMessage, cb) ->
    words = seedMessage.split delimiter
    @generateResponseSequence words, n, (sequence) ->
      sentence = sequence.join ' '
      cb sentence

  # Generate sequences starting from the n-grams in the given words
  # and pick the longest sequence.
  # wordN is the length of the ngrams to group the seed words into
  generateResponseSequence: (words, wordN, cb) ->
    # get n-grams in seed message
    if wordN <= 0
      # worse case: just start with a blank (random) prefix
      return @generateSequence n, [], maxWords, cb
    else if wordN == 1
      seedNgrams = ([word] for word in words)
    else
      m = wordN-2
      seedNgrams = (words[i..i+m] for a, i in words when i+m < words.length)
      if !seedNgrams.length
        return @generateResponseSequence words, wordN-1, cb

    # generate sequences from each ngram
    sequences = []
    seedNgrams.forEach (ngram) =>
      @generateSequence n, ngram, maxWords, (seq) =>
        # maybe include last word of initial ngram
        if seq.length and Math.random() < .25
          seq.unshift ngram.pop()
        # this sentence is a possible option
        sequences.push seq
        if sequences.length == seedNgrams.length
          # convert longest sequence into a string and return it
          longest = sequences.reduce (a, b) ->
            if b.length > a.length then b else a
          if longest.length == 0 or wordsContains longest, words
            # try smaller seed word groupings if the message is empty
            # or a copy of the seed meessage
            @generateResponseSequence words, wordN-1, cb
          else
            # use this sequence
            cb longest

  # Generate a Markov chain starting with the words in prefix
  generateSequence: (n, prefix, maxlen, cb, retries) ->
    if maxlen == 0 then return cb []
    @picker.getNgram n, prefix, (ngram) =>
      if ngram == null
        cb []
      else
        if @isBadNgram ngram
          retries |= 0
          if retries < badWordRetryLimit
            console.log 'try to find a better ngram', retries
            # try to find a better ngram
            @generateSequence n, prefix, maxlen, cb, retries+1
          else
            # give up
            console.log 'give up', retries
            cb []
        else
          newWords = ngram[prefix.length..]
          nextPrefix = ngram[1-n..]
          # empty string in the ngram means end of line
          if ngram[n-1] == ''
            while newWords[newWords.length-1] == ''
              newWords.pop()
            cb newWords
          else
            @generateSequence n, nextPrefix, maxlen-1, (tail) ->
              cb newWords.concat tail

  isBadNgram: (ngram) ->
    @bot.isBadNgram ngram

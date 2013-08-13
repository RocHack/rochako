request = require 'request'

wordsContains = (words, allWords) ->
  -1 != (allWords.join ' ').indexOf words.join ' '

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
  #console.log m, wordN, seedNgrams, words
  if wordN <= 0
    #console.log 'a'
    # worse case: just start with a blank (random) prefix
    return @generateSequence n, [], maxWords, cb
  else if wordN == 1
    #console.log 'b'
    seedNgrams = ([word] for word in words)
  else
    m = wordN-2
    seedNgrams = (words[i..i+m] for a, i in words when i+m < words.length)
    if !seedNgrams.length
      #console.log 'c'
      return @generateResponseSequence words, wordN-1, cb

  # generate sequences from each ngram
  sequences = []
  seedNgrams.forEach (ngram) ->
    #console.log 'asf', ngram
    @generateSequence n, ngram, maxWords, (seq) ->
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
          @generateResponseSequence words, wordN-1, cb
        else
          # use this sequence
          cb longest

# Generate a Markov chain starting with the words in prefix
generateSequence: (n, prefix, maxlen, cb, retries) ->
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
          @generateSequence n, prefix, maxlen, cb, retries+1
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
          @generateSequence n, nextPrefix, maxlen-1, (tail) ->
            cb newWords.concat tail



class Censorship
  constructor: ({@polite=false, @badWords={}}) ->

  _isBadWord: (word, channel) =>
    nicksInChannel = {} #channel.nicks
    #if word == myNick then return no
    if @badWords[word] or nicksInChannel[word] then return yes
    word = word.toLowerCase()
    for badWord of @badWords
      return yes if -1 != word.indexOf badWord
    for nick of nicksInChannel
      return yes if -1 != word.indexOf nick.toLowerCase()

  isBadNgram: (ngram) ->
    @polite and ngram.some @_isBadWord

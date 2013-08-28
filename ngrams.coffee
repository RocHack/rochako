request = require 'request'

class @NgramPicker

  constructor: ({db, @prefix, @debug}) ->
    @designDocUrl = db + '/_design/couchgrams/'

  getNgram: (n, seed, cb) ->
    if @prefix
      seed = seed.concat @prefix

    # n should be 3, maybe 2. couchgrams is too slow for 1 currently
    if n <= 1
      return cb ['fail']
    # alternate method is faster when there are more ngrams
    if n < 4
      return @_getNgram2 n, seed, cb
    # seed should be an array of length < n
    # cb will be called with an array prefixed by seed
    request.get
      url: @designDocUrl + '_list/pick_ngram/ngrams'
      qs:
        non_empty: true
        group_level: n
        startkey: JSON.stringify seed
        endkey: JSON.stringify seed.concat {}
      json: true
    , (error, resp, ngram) =>
      if resp?.statusCode != 200
        console.error 'failed to get ngram:', seed, error || resp?.statusCode, ngram
        return
      if ngram and !ngram.slice then ngram = []
      if @debug then console.log (seed.join ' '), '-->', ngram?.join ' '
      cb ngram

  _getNgram2: (n, seed, cb) ->
    # seed should be an array of length < n
    # cb will be called with an array prefixed by seed
    startkey = JSON.stringify seed
    endkey = JSON.stringify seed.concat {}
    request.get
      url: url = @designDocUrl + '_view/ngrams'
      qs: qs = {startkey, endkey}
      json: true
    , (error, resp, body) =>
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
        url: @designDocUrl + '_list/pick_ngram/ngrams'
        qs:
          descending: descending
          i: index
          group_level: n
          startkey: startkey
          endkey: endkey
        json: true
      , (error, resp, ngram) =>
        if resp?.statusCode != 200
          console.error 'failed to get ngram:', seed, error || resp?.statusCode, ngram
          return
        if ngram and !ngram.slice then ngram = []
        if @debug then console.log (seed.join ' '), '-->', ngram?.join ' '
        cb ngram

  # log a message and learn its ngrams
  log: (message, sender, channel) ->
    if @debug
      logmsg = if @skiplog then 'skipping log:' else 'logging:'
      console.log logmsg, message
    if @skiplog
      return
    data =
      text: message
      sender: sender
      channel: channel
    request.put
      url: url = @designDocUrl + '_update/add_text'
      json: data
    , (error, resp, body) ->
      if body != 'ok'
        console.error 'failed to log: ', url, data, resp?.statusCode, error || body

  # look up a karma value
  getKarma: (name, cb) ->
    request.get @designDocUrl + '_rewrite/karma/' + name, (error, resp, body) ->
      cb +body || 0


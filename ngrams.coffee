request = require 'request'

class @NgramPicker

  constructor: ({db, @debug, @sender, @skiplog}) ->
    @prefix = [@sender or null]
    @prefixLen = 1
    @designDocUrl = db + '/_design/couchgrams/'
    # sender is the nick to imitate.
    # If sender is null, use ngrams from all senders.

  getNgram: (n, seed, cb) ->
    prefix = @prefix.concat seed

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
        group_level: @prefixLen + n
        startkey: JSON.stringify prefix
        endkey: JSON.stringify prefix.concat {}
      json: true
    , (error, resp, ngram) =>
      if resp?.statusCode != 200
        console.error 'failed to get ngram:', seed, error || resp?.statusCode, ngram
        return
      if ngram
        # remove the sender prefix from the ngram result
        ngram = ngram?[@prefixLen..] or []
      if @debug then console.log (seed.join ' '), '-->', ngram?.join ' '
      cb ngram

  _getNgram2: (n, seed, cb) ->
    prefix = @prefix.concat seed
    # seed should be an array of length < n
    # cb will be called with an array prefixed by seed
    startkey = JSON.stringify prefix
    endkey = JSON.stringify prefix.concat {}
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
          group_level: @prefixLen+n
          startkey: startkey
          endkey: endkey
        json: true
      , (error, resp, ngram) =>
        if resp?.statusCode != 200
          console.error 'failed to get ngram:', seed, error || resp?.statusCode, ngram
          return
        if ngram
          # remove the sender prefix from the ngram result
          ngram = ngram?[@prefixLen..] or []
        if @debug then console.log (seed.join ' '), '-->', ngram?.join ' '
        cb ngram

  # log a message and learn its ngrams
  log: (message, sender, channel) ->
    if @debug and @skiplog != 'silent'
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


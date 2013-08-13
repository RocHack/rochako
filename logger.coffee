
# log a message
exports = (message, sender, channel) ->
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


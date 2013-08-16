request = require 'request'
{Tumblr} = require 'tumblr'

zeropad = (n) -> ('00' + n).substr(-1)
spacepad = (str) -> ('                ' + str).substr(-16)

docsToHTML = (docs) ->
  inner = docs.map (doc) ->
    d = new Date doc._id
    zeropad(d.getHours()) + ':' + zeropad(d.getMinutes()) +
      doc.sender + ' | ' + doc.text
  .join '<br>\n'
  "<pre>#{inner.replace /</g, '&lt;'}</pre>"

class @TumblrService

  constructor: (bot, {@host, @key}={}) ->
    if @host and @key
      bot.registerCommand 'highlight', @highlight

  highlight: (args, service, from, channel) =>
    service.say channel, 'todo'

  postDocsToTumblr: (docs, cb) ->
    request.post
      url: "https://api.tumblr.com/v2/blog/#{@host}/post"
      body:
        api_key: @key
        type: 'text'
        body: docsToHTML docs
    , (error, resp, body) ->
      if error or resp?.statusCode != 201
        cb false
      else
        url = resp.headers?['Location']
        cb url or try JSON.stringify resp

{Tumblr} = require 'tumblr'

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



{EventEmitter} = require 'events'
readline = require 'readline'
http = require 'http'

# curl -d hello localhost:8050/conversation

class @APIService extends EventEmitter

  constructor: (@bot, {port, @debug}) ->
    port or= 80
    @server = http.createServer @serve
    @server.listen port
    console.log 'API listening on port', port

  nameRegex: /^\/?([^\/]*)/

  serve: (req, res) =>
    if m = @nameRegex.exec req.url
      imitate = m[1]
      if req.method == 'POST'
        @readData req, @respond.bind @, res, imitate
      else
        res.statusCode = 405
        res.end 'Method not allowed\n'
    else
      res.statusCode = 404
      res.end 'Not found\n'

  readData: (req, cb) ->
    body = ''
    req.on 'data', (chunk) ->
      body += chunk
    req.on 'end', ->
      cb body

  respond: (res, imitate, msg) =>
    if @debug
      console.log "API(#{imitate}) #{msg}"
    @bot.imitateResponse msg, imitate, (response) ->
      res.writeHead 200, 'Content-Type': 'text/plain'
      res.end response

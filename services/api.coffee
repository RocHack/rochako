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

  serve: (req, res) =>
    if req.url == '/conversation'
      if req.method == 'POST'
        @readData req, @respond.bind @, res
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

  respond: (res, msg) =>
    if @debug
      console.log 'API message', msg
    @bot.generateResponse msg, (response) ->
      res.writeHead 200, 'Content-Type': 'text/plain'
      res.end response

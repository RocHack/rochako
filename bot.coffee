Conversations = require 'conversations'
services = require('./services')

commandRegex = new RegExp "^#{myNick}:?\\s*/(.*)$"

class Bot

  constructor: (@config) ->

    @selfPingRegex = new RegExp "^#{myNick}: "
    @selfStartRegex = new RegExp "^#{myNick} "
    @selfDoubleStartRegex = new RegExp "^#{myNick} #{myNick} "

    @conversations = new Conversations(this)
    @censorship = new Censorship(this)
    @services = []

  # generate and send a message in response to a message received
  respondTo: (service, message, sender) ->
    if debug then console.log '-->', message
    @conversations.generateResponse message, (response) ->
      # don't talk to self
      if 0 == response.indexOf "#{myNick}: "
        console.log 'removing self address'
        response = response.replace @selfPingRegex, ''

      # use /me instead of naming self
      else if 0 == response.indexOf "#{myNick} "
        # unless it's doing a pokemon
        if 0 != response.indexOf "#{myNick} #{myNick}"
          response = response.replace @selfStartRegex, ''
          isAction = true

      # send message
      if isAction
        service.action sender, response
      else
        service.say sender, response

      # log own message
      log response, myNick, sender if response

      if debug then console.log '<--', response



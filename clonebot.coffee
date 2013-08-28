{merge} = require './util'

@factory = (Bot) ->
  class @CloneBot extends Bot

    suffixes: ['o', 'a', 'e', 'i', 'u', 'y', 'ina', 'icus', 'ando', 'emoto', 'oni', 'r']

    constructor: ({parentConfig, targetNick, service, channel}) ->
      # select an available nick based on the target nick
      nickIsTaken = true
      i = 0
      while nickIsTaken and i < @suffixes.length
        suffix = @suffixes[i++]
        cloneNick = targetNick + suffix
        nickIsTaken = service.nicksByChannel[channel]?[cloneNick]
      console.log "cloning #{targetNick} as #{cloneNick} in #{channel}"
      service.say channel, "Cloning #{targetNick}"

      ircServerOptions = merge service.options,
        channels: [channel]
        servers: null
        nick: cloneNick
        nickServPassword: null
        userName: cloneNick
        realName: "clone of #{targetNick}"
        chattiness: 0

      config = merge parentConfig,
        imitate: targetNick
        skiplog: 'silent'
        irc:
          servers: [ircServerOptions]
      super config

      @registerCommand 'quit', @_quitCommand

    _quitCommand: (args, service, from, channel) ->
      @quit "Terminated by #{from}"

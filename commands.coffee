@unknown = (args, service, from, channel) ->
  service.say channel, 'Unknown command ' + args[0]

@denied = (args, service, from, channel) ->
  service.say channel, "Cannot use /#{args[0]} here"

commands =
  help: (args, service, from, channel) ->
    cmds = @effectiveCommands(service, channel).join ', '
    service.say channel, 'Commands: ' + cmds

  karma: (args, service, from, channel) ->
    if name = args[1]
      service.bot.conversations.picker.getKarma name, (karma) ->
      #service.bot.db.getKarma name, (karma) ->
        service.say channel, name + ': ' + karma

  clone: (args, service, from, channel) ->
    if name = args[1]?.trim()
      @spawnClone service, channel, name
    else
      service.say channel, 'Usage: /clone <nick>'

  join: (args, service, from, channel) ->
    if chan = args.slice(1).join ' '
      if service.join
        service.say channel, 'Joining ' + chan
        service.join chan, ->
          console.log 'Joined channel'
      else
        service.say channel, 'Unable to join ' + chan
    else
      service.say channel, 'Usage: /join <channel>'

  leave: (args, service, from, channel) ->
    if service.leave
      service.leave channel, "Leaving because #{from} told me to", ->
        console.log 'Left channel', channel
    else
      console.error 'Failed to leave channel', channel
      service.say channel, 'I\'m stuck here.'

commands.join.isEffective = (service, channel) ->
  # can only join from a control channel
  channel in service.initialChannels

commands.leave.isEffective = (service, channel) ->
  # cannot quit from a control channel
  channel not in service.initialChannels

@register = (bot) ->
  for own name, fn of commands
    bot.registerCommand name, fn, fn.isEffective

@unknown = (args, service, from, channel) ->
  service.say channel, 'Unknown command ' + args[0]

commands =
  help: (args, service, from, channel) ->
    cmds = (name for own name of @commands).join ', '
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

@register = (bot) ->
  for own name, fn of commands
    bot.registerCommand name, fn

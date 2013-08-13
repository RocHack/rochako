
exports = (args, from, channel) ->
  cmds = (name for own name of commands).join ', '
  client.say channel, 'Commands: ' + cmds

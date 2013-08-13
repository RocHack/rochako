

exports = (args, from, channel) ->
  if name = args[1]
    getKarma name, (karma) ->
      client.say channel, name + ': ' + karma

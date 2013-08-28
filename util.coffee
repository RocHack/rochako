@merge = (first, second) ->
  both = {}
  both[k] = v for k, v of first
  both[k] = v for k, v of second
  both


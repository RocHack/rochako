

useStdin = !live && process.argv[2] == '-'

# generate a response and exit
if useStdin
  readline = require 'readline'
  rl = readline.createInterface process.stdin, process.stdout
  question = ->
    rl.question '> ', (input) ->
      generateResponse input, (sentence) ->
        console.log sentence
        question()
  question()
  return

else
  input = process.argv.slice(2).join(' ')
  generateResponse input, (sentence) ->
    console.log sentence
    process.exit 0

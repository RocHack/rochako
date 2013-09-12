rochako
=======

IRC Bot in CoffeeScript

Features
--------

- Responds with Markov chains
- Logs to CouchDB
- Can clone specific nicks
- Can communicate through arbitrary services
- Has an HTTP API

API
---

POST message text to `http://localhost:8050/[sender]`, where `[sender]` can be
optionally given to narrow down the corpus to messages from a particular sender.
rochako generates a response and returns it as plain text.

CLI
---

The command line conversation interface can be enabled by setting `cli` to
`true` in `config.coffee`, or by passing `-` as the first argument when running
the bot (`./main.coffee -`).

Each line the CLI recieves on stdin is read and the response printed in a line to stdout.

ngrams
------

The Markov chains are generated with the help of the [couchgrams](https://github.com/clehner/couchgrams) CouchApp.


rochako
=======

IRC Bot in CoffeeScript

Features
--------

- Responds with Markov chains
- Logs to CouchDB
- Can clone specific nicks
- Can communicate through arbitrary services
- Has a basic HTTP API

API
---

POST message text to `http://localhost:8050/[sender]`, where `[sender]` can be
optionally given to narrow down the corpus to messages from a particular sender.
rochako generates a response and returns it as plain text.

ngrams
------

The Markov chains are generated with the help of the [couchgrams](https://github.com/clehner/couchgrams) CouchApp.


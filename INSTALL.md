Installation
------------

Update `cred.coffee` with connection info for your CouchDB database with couchgrams.

    cp cred.example.coffee cred.coffee
    vi cred.coffee

Install CoffeeScript if you don't have it

    npm install -g coffee-script

Run

    ./rochako.coffee

If you want to get a log of channel messages that weren't posted to CouchDB, use

    ./rochako.coffee 2>>error.log

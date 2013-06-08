Installation
------------

Get dependencies

    git submodule init
	git submodule update

Install CoffeeScript if you don't have it

    npm install -g coffee-script

Update `config.coffee` with connection info for your CouchDB database with couchgrams.

    cp config.example.coffee config.coffee
    vi config.coffee

Run

    ./rochako.coffee

If you want to get a log of channel messages that weren't posted to CouchDB, use

    ./rochako.coffee 2>>error.log

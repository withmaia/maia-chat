polar = require 'somata-socketio'
somata = require 'somata'
config = require './config'

client = new somata.Client

app = polar config

app.get '/', (req, res) -> res.render 'index', {config}

app.post '/command.json', (req, res) ->
    client.remote 'sample', 'sample', req.body.command, (err, response) ->
        console.log 'response', response
        res.json response

app.start()

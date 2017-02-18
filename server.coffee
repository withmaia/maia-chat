polar = require 'polar'
somata = require 'somata'
config = require './config'

client = new somata.Client

allowOrigin = (origin) -> (req, res, next) ->
    res.setHeader 'Access-Control-Allow-Origin', origin
    res.setHeader 'Access-Control-Allow-Headers', 'Content-Type'
    next()

app = polar config,
    middleware: [allowOrigin('*')]

app.get '/', (req, res) -> res.render 'index', {config}

app.post '/command.json', (req, res) ->
    client.remote 'sample', 'sample', req.body.command, (err, response) ->
        console.log 'response', response
        res.json response

app.start()

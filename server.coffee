polar = require 'somata-socketio'
somata = require 'somata'

client = new somata.Client

app = polar port: 4444

app.get '/', (req, res) -> res.render 'index'

app.post '/command.json', (req, res) ->
    client.remote 'sample', 'sample', req.body.command, (err, response) ->
        console.log 'response', response
        res.json response

app.start()

somata = require 'somata'
generateResponseBody = require './responses'

client = new somata.Client

service_aliases = {
    lights: "maia:hue",
    switches: "maia:wemo",
    music: "juicebox",
}

MIN_PROB = -0.05

command = (body, cb) ->
    if body.length < 2
        cb 'Input is too short'
    else if body.length > 50
        cb 'Input is too long'
    else
        client.remote 'maia:parser', 'parse', body, (err, response) ->
            if err
                console.log '[parsed ERROR]', err
                return cb err
            console.log '[parsed]', response
            if response.prob > MIN_PROB and response.parsed.length
                {parsed, prob} = response
                [service, command, args...] = parsed
                if service_alias = service_aliases[service]
                    service = service_alias
                client.remote service, command, args..., (err, response) ->
                    console.log '[response]', err or response
                    {response, parsed, prob} = generateResponseBody {response, parsed, prob}
                    cb null, {response, parsed, prob}

            else
                cb null, response

new somata.Service 'maia:command', {command}

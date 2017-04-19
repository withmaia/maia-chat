nalgene = require 'nalgene'
grammar = nalgene.parse require './grammar'

module.exports = generateResponseBody = ({response, parsed, prob}) ->
    console.log '[generateResponseBody]', response, parsed, prob

    if prob < -0.05
        context = {}
        entry = '%dontknow'

    else if parsed[0] == 'weather'
        if key = parsed[3]
            context = {
                '$location': capitalize unslugify parsed[2]
            }
            suffix = ''
            suffix = 'º' if key == 'temperature'
            suffix = '%' if key == 'humidity'
            context['$key'] = key
            context['$value'] = response + suffix
            entry = '%gotWeather'
        else
            context = {
                '$location': capitalize unslugify parsed[2]
                '$conditions': response.conditions.join(' and ')
                '$temperature': response.temperature + 'º'
            }
            entry = '%gotWeather'

    else if parsed[0] == 'time'
        context = {
            '$time': response
        }
        entry = '%gotTime'

    else if parsed[0] == 'price'
        context = {
            '$price': response
            '$asset': parsed[2]
        }
        entry = '%gotPrice'

    else if parsed[0] == 'lights'

        if parsed[1] == 'getState'
            context = {
                '$device': unslugify parsed[2]
                '$state': if response.on then 'on' else 'off'
            }
            entry = '%gotState'

        else if parsed[1] == 'setState'
            context = {
                '$device': unslugify parsed[2]
                '$state': parsed[3]
            }
            entry = '%setState'

        else if parsed[1] == 'setStates'
            context = {
                '$devices': unslugify parsed[2]
                '$state': parsed[3]
            }
            entry = '%setState'

    else
        context = {}
        entry = '%fallback'

    body = nalgene.generate grammar, context, entry
    return {response, parsed, body, prob}


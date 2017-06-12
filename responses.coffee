nalgene = require 'nalgene'
grammar = nalgene.parse require './grammar'
{capitalize, unslugify, formatThousands} = require './helpers'

module.exports = generateResponseBody = ({response, parsed, prob, context}) ->
    context ||= {}
    console.log '[generateResponseBody]', response, parsed, prob, context

    if !response?
        if grammar.children_by_key['%' + parsed[0]]
            entry = '%' + parsed[0]
        else
            entry = '%dontknow'

    else if parsed[0] == 'weather'
        if key = parsed[3]
            context['$location'] = capitalize unslugify parsed[2]
            suffix = ''
            suffix = 'º' if key == 'temperature'
            suffix = '%' if key == 'humidity'
            context['$key'] = key
            context['$value'] = response + suffix
            entry = '%gotWeather'
        else
            context['$location'] = capitalize unslugify parsed[2]
            context['$conditions'] = response.conditions.join(' and ')
            context['$temperature'] = response.temperature + 'º'
            entry = '%gotWeather'

    else if parsed[0] == 'time'
        context['$time'] = response
        entry = '%gotTime'

    else if parsed[0] == 'price'
        asset = parsed[2]
        if asset.length == 3
            asset = asset.toUpperCase()
        else
            asset = capitalize asset
        context['$price'] = '$' + formatThousands response.price
        context['$high'] = '$' + formatThousands response.high
        context['$low'] = '$' + formatThousands response.low
        context['$volume'] = '$' + formatThousands response.volume * response.price
        context['$asset'] = asset
        context['$market'] = 'GDAX'
        entry = '%gotPrice'

    else if parsed[0] == 'lights'

        if parsed[1] == 'getState'
            context['$device'] = unslugify parsed[2]
            context['$state'] = if response.on then 'on' else 'off'
            entry = '%gotState'

        else if parsed[1] == 'setState'
            context['$device'] = unslugify parsed[2]
            context['$state'] = parsed[3]
            entry = '%setState'

        else if parsed[1] == 'setStates'
            context['$devices'] = unslugify parsed[2]
            context['$state'] = parsed[3]
            entry = '%setState'

    else
        entry = '%fallback'

    body = nalgene.generate grammar, context, entry
    return body


Kefir = require 'kefir'
async = require 'async'
moment = require 'moment-timezone'
moment.tz('America/Los_Angeles')
util = require 'util'
commands = require './commands'
somata = require 'somata'
nalgene = require '../nalgene-js/src'
{asSentence} = require '../nalgene-js/src/helpers'
fs = require 'fs'
grammar = nalgene.parse fs.readFileSync './grammar.nlg', 'utf8'
request = require 'request'
{randomString, formatPrice} = require './helpers'

CHECK_COMPARISONS_EVERY = 1000 * 60
CHECK_TIMERS_EVERY = 1000

# Helpers
# ------------------------------------------------------------------------------

flatten = (ls) ->
    flat = []
    for l in ls
        for i in l
            flat.push i
    return flat

wrap = (s) ->
    '[' + s + ']'

inspect = (k, o) ->
    console.log wrap(k), util.inspect o, {depth: null, colors: true}

trimObj = (o) ->
    for k, v of o
        if !v?
            delete o[k]
    return o

findChild = (key, children) ->
    for child in children
        if child.key == key
            return child.children

objectToChildren = (obj) ->
    children = []
    for key, value of trimObj obj
        if typeof value == 'string'
            value = value.replace(/_/g, ' ')
        children.push {key: '$' + key, children: value}
    return children

asValueArray = (o) ->
    vs = []
    for k, v of trimObj o
        vs.push '$' + k
        vs.push v
    return vs

parseNumber = (n) ->
    Number n.replace(/\s+/g, '')

Array.remove = (list, item) ->
    index = list.indexOf item
    list.splice(index, 1)

# Message sending
# ------------------------------------------------------------------------------

generateResponse = (response) ->
    console.log 'response', response
    if response.key == '%sequence'
        for child in response.children
            if child.key == '%action'
                if child.children[0].key == '%getPrice'
                    getPrice = child.children[0]
                    console.log 'getPrice', getPrice
                    for gc in getPrice.children
                        if typeof gc.children == 'number'
                            console.log 'number', gc.children
                            gc.children = formatPrice gc.children
    context = {key: "%parsed", children: [response]}
    body = nalgene.generate grammar, '%response', context
    body = asSentence body
    console.log '[generateResponse]', body
    return body

sendResponse = (context, err, data) ->
    console.log '[send]', err or data

    if !err?
        response = generateResponse data

    if context.callback_url?
        sendPostResponse context, err, response

    else if context.session_id?
        sendChatResponse context, err, response

sendPostResponse = (context, err, response) ->
    if err?
        event_type = 'error'
    else
        event_type = 'message'

    post_body = {
        type: event_type
        body: err or response,
        receiver: context.sender?.username
    }
    request.post {uri: context.callback_url, json: post_body}

sendChatResponse = (context, err, response) ->
    message = {
        _id: randomString()
        body: response
        sender: 'maia'
    }
    client.remote 'maia:chat', 'sendResponse', context.session_id, message, ->

# Timer %timer commands
# ------------------------------------------------------------------------------

now = -> new Date().getTime()

checkTimer = (timer) ->
    if now() >= timer.time
        {sequence, context} = timer
        console.log '[checkTimer] Timer done at', moment().toISOString()
        Array.remove(timers, timer)
        runSequence context, sequence, sendResponse.bind(null, context)

timers = []
checkTimers = -> timers.map checkTimer
setInterval checkTimers, CHECK_TIMERS_EVERY

# Comparisons for %if commands
# ------------------------------------------------------------------------------

operatorFn = (operator) ->
    if operator == 'greater_than'
        return (a, b) -> a > b
    else if operator == 'less_than'
        return (a, b) -> a < b
    else
        return (a, b) -> a == Math.floor b

checkComparison = (comparison) ->
    {action, operator, number, sequence, context, callback_url} = comparison

    runCommand context, action, (err, response) ->
        value = findChild('$value', response)
        if operatorFn(operator)(value, number)
            console.log '[checkComparison]', comparison, 'is true'
            runSequence context, sequence, sendResponse.bind(null, callback_url)
            Array.remove(comparisons, comparison)

comparisons = []
checkComparisons = -> comparisons.map checkComparison
setInterval checkComparisons, CHECK_COMPARISONS_EVERY

# ------------------------------------------------------------------------------

runIf = (context, args, cb) ->
    condition = findChild('%condition', args)
    sequence = findChild('%sequence', args)

    if getValue = findChild('%getValue', condition)
        operator = findChild('%operator', condition)[0]?.key?.slice(1)
        number = findChild('$number', condition)[0]
        number = parseNumber number
        inspect 'getValue', getValue
        inspect 'operator', operator
        inspect 'number', number
        action = getValue[0]
        comparisons.push {action, operator, number, sequence}

    else if checkValue = findChild('%checkValue', condition)
        inspect 'checkValue', checkValue

    cb null, {key: '%if', children: []}

runTimer = (context, args, cb) ->
    absolute_time = findChild('%absolute_time', args)
    relative_time = findChild('%relative_time', args)
    sequence = findChild('%sequence', args)

    if absolute_time?
        time_str = findChild('$time', absolute_time).join(' ')

        for matcher in ['H a', 'H : mm a', 'H : mm']
            if moment(time_str, matcher, true).isValid()
                time = moment(time_str, matcher, true)
                break

        if !time?
            return cb "Could not parse time #{time_str}"

        if time.isBefore(moment())
            console.log '(absolute time) adjust +1 day'
            time.add(1, 'day')

        inspect 'absolute time', {time}
        timeout = time.diff(moment())

    else if relative_time?
        number = findChild('$number', relative_time)
        number = parseNumber number.join('')
        time_unit = findChild('%time_unit', relative_time)
        time_unit = time_unit[0].key.slice(1)
        inspect 'relative time', {number, time_unit}

        if time_unit == 'seconds'
            timeout = number * 1000
        else if time_unit == 'minutes'
            timeout = number * 1000 * 60
        else if time_unit == 'hours'
            timeout = number * 1000 * 60 * 60

    console.log '[runTimer] Starting timer', timeout, 'at', moment().toISOString(), '...\n'
    time = now() + timeout
    timers.push {time, sequence, context}

    from_now = moment(time).fromNow()
    cb null, {key: '%timer', children: objectToChildren {from_now}}

argsFromChildren = (children) ->
    inspect 'argsFromChildren', children
    args = {}
    for child in children
        child_key = child.key.slice(1)
        child_value = child.children[0]
        if child_value?.key?[0] == '@'
            child_value = child_value.key.slice(1)
            args[child_key] = child_value
        else if child_value?.key?[0] == '$'
            child_value = argsFromChildren child.children
        args[child_key] = child_value
    inspect 'argsFromChildren args =', args
    return args

runCommand = (context, {key, children}, cb) ->
    if command = commands[key.slice(1)]
        args = argsFromChildren children
        command args, (err, response) ->
            return cb err if err?
            cb null, objectToChildren response
    else
        cb "Unknown command #{command}"

runAction = (context, {key, children}, cb) ->
    console.log '[runAction]', key, children
    action = children[0]
    runCommand context, action, (err, response) ->
        if err?
            cb err
        else
            key = action.key
            inspect 'runAction response', response
            cb null, {key: '%action', children: [{key, children: response}]}

runSequence = (context, args, cb) ->
    inspect 'runSequence args', args
    async.mapSeries args, runAction.bind(null, context), (err, responses) ->
        if err
            cb err
        else
            inspect 'runSequence responses', responses
            cb null, {key: '%sequence', children: responses}

runners =
    '%timer': runTimer
    '%if': runIf
    '%sequence': runSequence

passthrough =
    '%greeting': true
    '%thanks': true

runPhrase = (context, {key, children}, cb) ->
    inspect 'runPhrase', {key, children, context}
    if run = runners[key]
        run context, children, cb
    else if passthrough[key]
        cb null, {key, children}
    else if command = commands[key.slice(1)]
        args = argsFromChildren children
        command args, (err, response) ->
            return cb err if err?
            cb null, {
                key: '%sequence'
                children: [
                    {
                        key: '%action'
                        children: [
                            {
                                key: key
                                children: objectToChildren response
                            }
                        ]
                    }
                ]
            }
    else
        cb "Don't understand #{key}"

# Running service
# ------------------------------------------------------------------------------

client = new somata.Client

command = (message, cb) ->
    context = {}
    Object.assign context, message
    console.log '[command]', message

    client.remote 'maia:parser', 'parse', message.body, (err, response) ->
        if err or err = response.error
            return sendResponse context, err

        inputs = response.parsed.children[0]

        runPhrase context, inputs, sendResponse.bind(null, context)

# Test
# c = 'in 7 seconds please turn on the kitchen light and turn off the living room light'
# c = 'when the price of bitcoin is above 100 please turn on the kitchen light'
# c = 'please turn on the kitchen light and turn off the living room light'
# c = 'when the price of bitcoin is above 2650 turn the office light green'
c = 'what is the price of bitcoin?'
callback_url = 'http://webhooks.nexus.dev/events/bot/kihu1tze'
command {body: c, callback_url, sender: {username: 'jones'}}, (err, got) -> console.log err or got

# new somata.Service 'maia:command', {command}


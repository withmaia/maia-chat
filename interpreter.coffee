Kefir = require 'kefir'
async = require 'async'
moment = require 'moment-timezone'
moment.tz('America/Los_Angeles')
util = require 'util'
commands = require './commands'
somata = require 'somata'
nalgene = require '../nalgene-js/src'
{asSentence} = require '../nalgene-js/src/helpers'
grammar = nalgene.parse require './grammar'

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
    context = {key: "%parsed", children: [response]}
    body = nalgene.generate grammar, '%response', context
    body = asSentence body
    console.log '[generateResponse]', body
    return body

send = (err, data) ->
    console.log '[send]', err or data

sendMessage = (err, data) ->
    if err?
        send err
    else
        response = generateResponse data
        send null, response

# Comparisons for %if commands
# ------------------------------------------------------------------------------

operatorFn = (operator) ->
    if operator in ['above', 'greater than']
        return (a, b) -> a > b
    else if operator in ['below', 'less than']
        return (a, b) -> a < b
    else
        return (a, b) -> a == Math.floor b

checkComparison = (comparison) ->
    {action, operator, number, sequence} = comparison

    runCommand action, (err, response) ->
        value = findChild('$value', response)
        if operatorFn(operator)(value, number)
            console.log '[checkComparison]', comparison, 'is true'
            runSequence sequence, sendMessage
            Array.remove(comparisons, comparison)

comparisons = []
checkComparisons = -> comparisons.map checkComparison
setInterval checkComparisons, CHECK_COMPARISONS_EVERY

# Timer %timer commands
# ------------------------------------------------------------------------------

now = -> new Date().getTime()

checkTimer = (timer) ->
    if now() >= timer.time
        {sequence} = timer
        console.log '[checkTimer] Timer done at', moment().toISOString()
        Array.remove(timers, timer)
        runSequence sequence, sendMessage

timers = []
checkTimers = -> timers.map checkTimer
setInterval checkTimers, CHECK_TIMERS_EVERY

# ------------------------------------------------------------------------------

runIf = (args, cb) ->
    condition = findChild('%condition', args)
    sequence = findChild('%sequence', args)

    if getValue = findChild('%getValue', condition)
        operator = findChild('$operator', condition)[0]
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

runTimer = (args, cb) ->
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
        time_unit = findChild('$time_unit', relative_time)?[0]
        inspect 'relative time', {number, time_unit}
        if time_unit == 'seconds'
            timeout = number * 1000
        else if time_unit == 'minutes'
            timeout = number * 1000 * 60
        else if time_unit == 'hours'
            timeout = number * 1000 * 60 * 60

    console.log '[runTimer] Starting timer', timeout, 'at', moment().toISOString(), '...\n'
    time = now() + timeout
    timers.push {time, sequence}

    from_now = moment(time).fromNow()
    cb null, {key: '%timer', children: objectToChildren {from_now}}

parseArgs = (args) ->
    inspect 'parseArgs', args
    parsed = {}
    for arg in args
        parsed[arg.key.slice(1)] = arg.children[0]
    return parsed

runCommand = ({key, children}, cb) ->
    if command = commands[key.slice(1)]
        args = parseArgs children
        command args, (err, response) ->
            return cb err if err?
            cb null, objectToChildren response
    else
        cb "Unknown command #{command}"

runAction = ({key, children}, cb) ->
    console.log '[runAction]', key, children
    action = children[0]
    runCommand action, (err, response) ->
        if err?
            cb err
        else
            key = action.key
            inspect 'runAction response', response
            cb null, {key: '%action', children: [{key, children: response}]}

runSequence = (args, cb) ->
    inspect 'runSequence args', args
    async.mapSeries args, runAction, (err, responses) ->
        if err
            cb err
        else
            inspect 'runSequence responses', responses
            cb null, {key: '%sequence', children: responses}

runners =
    '%timer': runTimer
    '%if': runIf
    '%sequence': runSequence

runPhrase = ({key, children}, cb) ->
    inspect 'runPhrase', {key, children}
    if run = runners[key]
        run children, cb
    else
        cb "Don't understand #{key}"

# Running service
# ------------------------------------------------------------------------------

client = new somata.Client

command = (message, cb) ->
    send = cb

    client.remote 'maia:parser', 'parse', message.body, (err, response) ->
        if err or err = response.error
            return sendMessage err

        inputs = response.parsed.children[0]

        runPhrase inputs, (err, data) ->
            if err?
                console.log "FAILED", err
                sendMessage err
            else
                inspect "Response", data
                sendMessage null, data

# Test
# c = 'please turn on the kitchen light and turn off the living room light'
# c = 'in 7 seconds please turn on the kitchen light and turn off the living room light'
# c = 'when the price of bitcoin is above 100 please turn on the kitchen light'
# command {body: c}, (err, got) -> console.log err or got

new somata.Service 'maia:command', {command}


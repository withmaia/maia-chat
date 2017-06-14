Kefir = require 'kefir'
async = require 'async'
moment = require 'moment-timezone'
moment.tz('America/Los_Angeles')
util = require 'util'
commands = require './commands'
respond = require './respond'
somata = require 'somata'

wrap = (s) ->
    '[' + s + ']'

inspect = (k, o) ->
    console.log wrap(k), util.inspect o, {depth: null, colors: true}

group = (list, group_by=2) ->
    grouped = []
    for a in [0...Math.floor(list.length / group_by)]
        grouped.push list.slice(a * group_by, (a + 1) * group_by)
    return grouped

parseNumber = (n) ->
    Number n.replace(/\s+/, '')

# ------------------------------------------------------------------------------

findArgs = (key, args) ->
    console.log 'find args', key, args
    for [arg_name, arg_value] in group args
        console.log 'arg name', arg_name
        if arg_name == key
            return arg_value

findArg = (key, args) ->
    console.log 'joined', findArgs(key, args)?.join(' ')
    findArgs(key, args)?.join(' ')

runTimer = (args, cb) ->
    absolute_time = findArgs('%absolute_time', args)
    relative_time = findArgs('%relative_time', args)

    sequence = findArgs '%sequence', args

    if absolute_time?
        time_str = findArgs('$time', absolute_time).join(' ')

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
        number = findArgs('$number', relative_time)
        number = parseNumber number.join('')
        time_unit = findArgs('$time_unit', relative_time)?[0]
        inspect 'relative time', {number, time_unit}
        if time_unit == 'seconds'
            timeout = number * 1000
        else if time_unit == 'minutes'
            timeout = number * 1000 * 60
        else if time_unit == 'hours'
            timeout = number * 1000 * 60 * 60

    console.log 'Starting timer', timeout, 'at', moment().toISOString(), '...\n'

    setTimeout ->
        console.log 'Timer done at', moment().toISOString()
        runSequence sequence, cb
    , timeout

trimObj = (o) ->
    for k, v of o
        if !v?
            delete o[k]
    return o

asValueArray = (o) ->
    vs = []
    for k, v of trimObj o
        vs.push '$' + k
        vs.push v
    return vs

runCommand = ([key, args], cb) ->
    console.log 'key', key, 'args', args
    if command = commands[key.slice(1)]
        args = parseArgs args
        command args, (err, response) ->
            if err
                cb err
            else
                cb null, asValueArray response
    else
        cb "Unknown command #{command}"

runAction = (args, cb) ->
    # runPhrase args, (err, response) ->
    console.log 'runAction', args
    runCommand args, (err, response) ->
        if err?
            cb err
        else
            key = args[0]
            inspect 'runAction respoinse', response
            cb null, ['%action', [key, response]]

runSequence = (args, cb) ->
    args = group args
    inspect 'runSequence', args
    async.mapSeries args, runAction, (err, responses) ->
        if err
            cb err
        else
            responses.unshift '%sequence'
            cb null, responses

runners =
    '%timer': runTimer
    '%sequence': runSequence

parseArgs = (args) ->
    inspect 'parseArgs', args
    parsed = {}
    for a in [0...Math.floor(args.length / 2)]
        [arg_name, [arg_value]] = args.slice(a * 2, (a + 1) * 2)
        parsed[arg_name.slice(1)] = arg_value
    console.log 'parsed', parsed
    return parsed

runPhrase = ([key, args], cb) ->
    inspect 'runPhrase', {key, args}
    if run = runners[key]
        run args, cb
    else
        cb "Don't understand #{key}"

# ------------------------------------------------------------------------------

client = new somata.Client
command = (message, cb) ->
    client.remote 'maia:parser', 'parse', message.body, (err, response) ->
        inputs = response.evaluated
        inspect 'parsed input list', inputs
        runPhrase inputs, (err, results) ->
            if err?
                console.log "FAILED", err
                cb err
            else
                inspect "Response", results
                body = respond results
                cb null, body

new somata.Service 'maia:command', {command}


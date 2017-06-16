somata = require 'somata'
{randomString} = require './helpers'

client = new somata.Client

sessions = {}

welcome_message = {
    _id: 0
    sender: 'maia'
    body: """
        Hi there, I am Maia. You can call me @maia. I know how to do a few useful things, like "turn on the office light" or "turn off all the lights" or "set the bedroom lights low" or answer "what is the price of bitcoin?"
    """
}

addSession = (session_id, cb) ->
    console.log '[addSession]', session_id
    sessions[session_id] = {pending: []}
    service.publish 'messages:' + session_id, welcome_message
    cb null, 'added ' + session_id

sendMessage = (session_id, message, cb) ->
    console.log '[sendMessage]', session_id, message
    message.session_id = session_id
    client.remote 'maia:command', 'command', message, cb

sendResponse = (session_id, message, cb) ->
    console.log '[sendResponse]', session_id, message
    service.publish 'messages:' + session_id, message
    cb? null, 'sent response'

service = new somata.Service 'maia:chat', {addSession, sendMessage, sendResponse}


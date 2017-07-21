React = require 'react'
ReactDOM = require 'react-dom'
ReactContenteditable = require 'react-contenteditable'
reactStringReplace = require 'react-string-replace'
ReactCSSTransitionGroup = require 'react-addons-css-transition-group'
KefirBus = require 'kefir-bus'
fetch$ = require 'kefir-fetch'
KefirCollection = require 'kefir-collection'
somata = require 'somata-socketio-client'

somata.connect ->
    console.log '[connected]'

# Helpers

capitalizeFirst = (s) -> s[0].toUpperCase() + s.slice(1)
capitalize = (s) -> s.split(' ').map(capitalizeFirst).join(' ')

unslugify = (s) -> s.split('_').join(' ')

randomString = (len=8) ->
    s = ''
    while s.length < len
        s += Math.random().toString(36).slice(2, len-s.length+2)
    return s

# Messages

messages$ = KefirCollection([], id_key: '_id')
sent_message$ = KefirBus()

sendMessage = (m) ->
    sent_message$.emit {
        _id: randomString()
        sender: 'human'
        body: m
    }

# TODO: Don't use pending responses as there might be multiple
# for any given message (followups e.g. timer, condition)
sent_message$.onValue (message) ->
    messages$.createItem message
    somata.remote$('maia:chat', 'sendMessage', session_id, message)
        .onValue -> # Sent

# Start session

session_id = randomString()

received_message$ = somata.subscribe$('maia:chat', 'messages:' + session_id)
    .onValue (received) ->
        console.log '[received]', received
        messages$.createItem received

somata.remote$('maia:chat', 'addSession', session_id).onValue (added) ->
    console.log 'started session', added

NewMessage = React.createClass
    getInitialState: ->
        body: ''

    onChange: (e) ->
        body = e.target.value
        @setState {body}

    sendMessage: (e) ->
        e?.preventDefault()
        sendMessage @state.body
        @setState @getInitialState()

    onKeyDown: (e) ->
        if e.key == 'Enter'
            e.preventDefault()
            @sendMessage()

    focus: ->
        ReactDOM.findDOMNode(@refs.input).focus()

    render: ->
        <form className='new-message' onSubmit=@sendMessage>
            <input type='text' value=@state.body onChange=@onChange onKeyDown=@onKeyDown ref='input' />
            <button onClick=@sendMessage>Send</button>
        </form>

PlaceholderMessage = ->
    <div className='placeholder-message'>
        <img className='avatar' src='/images/maia.png' />
        . . .
    </div>

App = React.createClass
    getInitialState: ->
        messages: []

    componentDidMount: ->
        messages$.onValue @setMessages
        @fixScroll()
        @refs.input.focus()

    setMessages: (messages) ->
        @setState {messages}, @fixScroll

    sendMessage: (m) -> ->
        m = m.replace /"/g, ''
        sendMessage m

    fixScroll: ->
        el = document.body
        el.scrollTop = el.scrollHeight

    render: ->
        <div className='messages' ref='messages'>
            <ReactCSSTransitionGroup
                transitionName="message-animation"
                transitionEnterTimeout=500
                transitionLeaveTimeout=10
            >

            {@state.messages.map (message) =>
                <div className={'message ' + 'sender-' + message.sender + ' ' + message.type} key={'m_' + message._id}>
                    {if message.sender == 'maia'
                        <img className='avatar' src='/images/maia.png' />
                    else
                        <img className='avatar' src='/images/human.png' />
                    }

                    {if not (message.body? or message.response?)
                        <em className='pending'>...</em>

                    else if message.body?
                        <div>
                            {message.body.split('\n').map (line, li) =>
                                <p key={'li_' + li}>
                                    {replaced = reactStringReplace line, /("[^"]+")/g, (match, mi) =>
                                        <a key={'ma_quo_' + li + '_' + mi} onClick={@sendMessage(match)}>{match}</a>
                                    replaced = reactStringReplace replaced, /(@\w+)/g, (match, mi) =>
                                        <a key={'ma_men_' + li + '_' + mi} onClick={@sendMessage(match)}>{match}</a>
                                    replaced
                                    }
                                </p>
                            }
                            {if parsed = message.context?.parsed
                                <pre>{JSON.stringify parsed}</pre>
                            }
                        </div>

                    else if message.response?
                        <div>
                            <span className='parsed'>{message.parsed.join(' ')}</span>
                            <pre>
                                {JSON.stringify message.response}
                            </pre>
                        </div>
                    }

                    {if message.prob?
                        <span className='prob'>{message.prob.toFixed(2)}</span>
                    }
                </div>
            }

            </ReactCSSTransitionGroup>
            <NewMessage ref='input' />
        </div>

ReactDOM.render <App />, document.getElementById 'app'


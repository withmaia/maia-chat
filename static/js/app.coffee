React = require 'react'
ReactDOM = require 'react-dom'
ReactContenteditable = require 'react-contenteditable'
somata = require 'somata-socketio-client'
reactStringReplace = require 'react-string-replace'
ReactCSSTransitionGroup = require 'react-addons-css-transition-group'
KefirBus = require 'kefir-bus'
KefirCollection = require 'kefir-collection'

if config.debug?
    somata.subscribe 'reloader', 'reload', -> window.location = window.location

initial_messages = [
    {
        _id: 0
        sender: 'maia'
        body: """
            Hi there, I am Maia. You can call me @maia. I know how to do a few useful things... like "turn on the office light" or "turn off all the lights"
        """
    }
]

messages$ = KefirCollection([], id_key: '_id')
sent_message$ = KefirBus()

sendMessage = (m) ->
    sent_message$.emit {
        _id: Math.floor Math.random() * 9999 + 100
        sender: 'human'
        body: m
    }

ii = 1

sent_message$.onValue (message) ->
    ii += 1
    messages$.createItem message
    setTimeout ->
        messages$.createItem {_id: ii, sender: 'maia'}
        somata.remote 'sample', 'sample', message.body, (err, sampled) ->
            console.log '[sampled]', sampled
            if err?
                message = {body: "Oh no... " + err}
            else
                message = {body: sampled.response}
            messages$.updateItem ii, message
    , 200

messages$.createItem initial_messages[0]

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

    render: ->
        <form className='new-message' onSubmit=@sendMessage>
            <img src='/images/human.png' />
            <ReactContenteditable html=@state.body onChange=@onChange onKeyDown=@onKeyDown />
            <button onClick=@sendMessage>Send</button>
        </form>

PlaceholderMessage = ->
    <div className='placeholder-message'>
        <img src='/images/maia.png' />
        . . .
    </div>

App = React.createClass
    getInitialState: ->
        messages: []

    componentDidMount: ->
        messages$.onValue @setMessages
        @fixScroll()

    setMessages: (messages) ->
        @setState {messages}, @fixScroll

    filterMessages: (filter) ->
        messages = @state.messages
        messages = messages.filter filter
        @setState {messages}, @fixScroll

    sendMessage: (m) -> ->
        m = m.replace /"/g, ''
        sendMessage m

    fixScroll: ->
        document.body.scrollTop = document.body.scrollHeight

    render: ->
        <div className='messages'>
            <ReactCSSTransitionGroup
                transitionName="message-animation"
                transitionEnterTimeout=500
                transitionLeaveTimeout=10
            >
            {@state.messages.map (message) =>
                <div className={'message ' + message.sender} key={'m_' + message._id}>
                    {if message.sender == 'maia'
                        <img src='/images/maia.png' />
                    else
                        <img src='/images/human.png' />
                    }
                    {if !message.body?
                        <em className='pending'>...</em>
                    else if typeof message.body == 'object'
                        <pre>
                            {JSON.stringify message.body}
                        </pre>
                    else
                        message.body.split('\n').map (line, li) =>
                            <p key={'li_' + li}>
                                {replaced = reactStringReplace line, /("[^"]+")/g, (match, mi) =>
                                    <a key={'ma_quo_' + li + '_' + mi} onClick={@sendMessage(match)}>{match}</a>
                                replaced = reactStringReplace replaced, /(@\w+)/g, (match, mi) =>
                                    <a key={'ma_men_' + li + '_' + mi} onClick={@sendMessage(match)}>{match}</a>
                                replaced
                                }
                            </p>
                    }
                </div>
            }
            </ReactCSSTransitionGroup>
            <NewMessage />
        </div>

ReactDOM.render <App />, document.getElementById 'app'


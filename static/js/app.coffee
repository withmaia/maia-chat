React = require 'react'
ReactDOM = require 'react-dom'
ReactContenteditable = require 'react-contenteditable'
reactStringReplace = require 'react-string-replace'
ReactCSSTransitionGroup = require 'react-addons-css-transition-group'
KefirBus = require 'kefir-bus'
fetch$ = require 'kefir-fetch'
KefirCollection = require 'kefir-collection'

initial_messages = [
    {
        _id: 0
        sender: 'maia'
        body: """
            Hi there, I am Maia. You can call me @maia. I know how to do a few useful things, like "turn on the office light" or "turn off all the lights" or answer "what is the price of bitcoin?"
        """
    }
]

messages$ = KefirCollection([], id_key: '_id')
sent_message$ = KefirBus()

sendMessage = (m) ->
    sent_message$.emit {
        _id: new Date().getTime()
        sender: 'human'
        body: m
    }

postCommand = (command, cb) ->
    fetch$ 'post', 'http://withmaia.com/sample.json', {body: {command}}

sent_message$.onValue (message) ->
    messages$.createItem message
    response_id = new Date().getTime() + 1
    messages$.createItem {_id: response_id, sender: 'maia'}
    postCommand(message.body)
        .onValue (message) ->
            console.log '[message]', message
            messages$.updateItem response_id, message
        .onError (err) ->
            message = {error: "Oh no... " + err}

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
                    {if not (message.body? or message.response?)
                        <em className='pending'>...</em>
                    else if message.response?
                        <div>
                            <span className='parsed'>{message.parsed.join(' ')}</span>
                            <pre>
                                {JSON.stringify message.response}
                            </pre>
                        </div>
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


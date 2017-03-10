React = require 'react'
ReactDOM = require 'react-dom'
ReactContenteditable = require 'react-contenteditable'
reactStringReplace = require 'react-string-replace'
ReactCSSTransitionGroup = require 'react-addons-css-transition-group'
KefirBus = require 'kefir-bus'
fetch$ = require 'kefir-fetch'
KefirCollection = require 'kefir-collection'
nalgene = require 'nalgene'
grammar = nalgene.parse require './grammar'

capitalizeFirst = (s) -> s[0].toUpperCase() + s.slice(1)
capitalize = (s) -> s.split(' ').map(capitalizeFirst).join(' ')

unslugify = (s) -> s.split('_').join(' ')

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
        .map generateResponseBody

generateResponseBody = ({response, parsed, prob}) ->
    console.log 'sampled response', response, parsed, prob

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
            <img className='avatar' src='/images/human.png' />
            <ReactContenteditable html=@state.body onChange=@onChange onKeyDown=@onKeyDown />
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
                <div className={'message ' + message.sender} key={'m_' + message._id}>
                    {if message.sender == 'maia'
                        <img className='avatar' src='/images/maia.png' />
                    else
                        <img className='avatar' src='/images/human.png' />
                    }

                    {if not (message.body? or message.response?)
                        <em className='pending'>...</em>

                    else if message.body?
                        message.body.split('\n').map (line, li) =>
                            <p key={'li_' + li}>
                                {replaced = reactStringReplace line, /("[^"]+")/g, (match, mi) =>
                                    <a key={'ma_quo_' + li + '_' + mi} onClick={@sendMessage(match)}>{match}</a>
                                replaced = reactStringReplace replaced, /(@\w+)/g, (match, mi) =>
                                    <a key={'ma_men_' + li + '_' + mi} onClick={@sendMessage(match)}>{match}</a>
                                replaced
                                }
                            </p>

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
            <NewMessage />
        </div>

ReactDOM.render <App />, document.getElementById 'app'


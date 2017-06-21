somata = require 'somata'
{unslugify, formatPrice} = require './helpers'

client = new somata.Client

module.exports =
    getPrice: ({asset}, cb) ->
        # cb null, {asset, value: 200 * Math.random(), volume: 555, market: 'GDAX'}
        client.remote 'price', 'getPrice', asset, cb

    getTemperature: ({room_name}, cb) ->
        cb null, {room_name, value: 20 + 70 * Math.random()}

    getSwitchState: ({switch_name}, cb) ->
        cb null, {switch_name, value: Math.random() < 0.5}

    getLightState: ({light_name}, cb) ->
        # cb null, {light_name, light_state: if Math.random() < 0.5 then 'on' else 'off'}
        client.remote 'maia:hue', 'getState', light_name, cb

    getLightGroupState: ({light_group_name}, cb) ->
        # cb null, {light_group_name, light_state: if Math.random() < 0.5 then 'on' else 'off'}
        client.remote 'maia:hue', 'getStates', light_group_name, cb

    setVolume: ({up_down}, cb) ->
        cb null, {up_down}

    setTemperature: ({room_name, temperature}, cb) ->
        cb null, {room_name, temperature}

    setLightState: ({light_name, light_state}, cb) ->
        # cb null, {light_name, light_state}
        console.log 'light_state', light_state
        client.remote 'maia:hue', 'setState', light_name, light_state, (err, response) ->
            return cb err if err?
            console.log 'response', response
            nice_light_name = unslugify light_name
            if color = light_state.color
                light_state = color
            cb err, {
                light_name: nice_light_name
                light_state
            }

    setLightGroupState: ({light_group_name, light_state}, cb) ->
        # cb null, {light_group_name, light_state}
        client.remote 'maia:hue', 'setStates', light_group_name, light_state, (err, response) ->
            return cb err if err?
            console.log 'response', response
            if light_group_name == 'all_lights'
                nice_light_group_name = 'all the lights'
            else
                nice_light_group_name = 'the ' + unslugify light_group_name
            if color = light_state.color
                light_state = color
            cb err, {
                light_group_name: nice_light_group_name
                light_state
            }

    toggleLightState: ({light_name}, cb) ->
        # cb null, {light_name, light_state}
        client.remote 'maia:hue', 'toggleState', light_name, cb

    toggleLightGroupState: ({light_group_name}, cb) ->
        # cb null, {light_group_name, light_state}
        client.remote 'maia:hue', 'toggleStates', light_group_name, cb

    setSwitchState: ({switch_name, on_off}, cb) ->
        cb null, {switch_name, on_off}

    playMusic: ({song_name, artist_name}, cb) ->
        cb null, {song_name, artist_name}


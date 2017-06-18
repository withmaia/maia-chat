
module.exports =
    getPrice: ({asset}, cb) ->
        cb null, {asset, value: 200 * Math.random(), volume: 555, market: 'GDAX'}

    getTemperature: ({room_name}, cb) ->
        cb null, {room_name, value: 20 + 70 * Math.random()}

    getSwitchState: ({switch_name}, cb) ->
        cb null, {switch_name, value: Math.random() < 0.5}

    getLightState: ({light_name}, cb) ->
        cb null, {light_name, light_state: if Math.random() < 0.5 then 'on' else 'off'}

    setVolume: ({up_down}, cb) ->
        cb null, {up_down}

    setTemperature: ({room_name, temperature}, cb) ->
        cb null, {room_name, temperature}

    setLightState: ({light_name, light_state}, cb) ->
        cb null, {light_name, light_state}

    setSwitchState: ({switch_name, on_off}, cb) ->
        cb null, {switch_name, on_off}

    playMusic: ({song_name, artist_name}, cb) ->
        cb null, {song_name, artist_name}


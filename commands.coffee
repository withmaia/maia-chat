
module.exports =
    getPrice: ({asset}, cb) ->
        cb null, {asset, price: 55, volume: 555, market: 'GDAX'}

    setVolume: ({up_down}, cb) ->
        cb null, {up_down}

    setTemperature: ({room_name, temperature}, cb) ->
        cb null, {room_name, temperature}

    setLightState: ({light_name, on_off, up_down, color}, cb) ->
        cb null, {light_name, on_off, up_down, color}

    setSwitchState: ({switch_name, on_off}, cb) ->
        cb null, {switch_name, on_off}

    playMusic: ({song_name, artist_name}, cb) ->
        cb null, {song_name, artist_name}


module.exports = grammar = """
%fallback
    I'm not sure what happened.

%dontknow
    I don't understand.
    I didn't catch that.
    I don't know what you're saying.

%setState
    I turned the $device $state .
    I turned $state the $device .
    the $device is now $state .
    $devices are now $state .

%gotState
    the $device is $state .

%gotTime
    the time is $time .
    it is $time .

%gotPrice
    the price of $asset is ~currently? $price .
    $asset is ~currently? $price .

%gotWeather
    $location is ~currently? $temperature with $conditions .
    the $location $key is ~currently? $value .
    the $key of $location is ~currently? $value .

~currently
    currently

~ok
    ok,
    sure,
"""

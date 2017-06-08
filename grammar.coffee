module.exports = grammar = """
%fallback
    I'm not sure what happened.
    Sorry I think I'm having a mental breakdown.

%dontknow
    I didn't catch that.
    I don't understand.
    I don't ~understand ~what_you_said .
    Not sure what you're talking about.
    What?

~understand
    understand
    get
    know
    know how to parse

~what_you_said
    what you said
    what you're saying
    what you're talking about
    what that means

%thanks
    You're welcome.
    You are ~very? welcome.
    No, thank you.
    My pleasure.

~very
    very
    extremely
    so

%greeting
    Oh hai.
    Hey there.
    Hello!

%setState
    I turned the $device $state .
    the $device is now $state .
    $devices are now $state .

%gotState
    ~looks_like? the $device is $state .

%gotTime
    ~looks_like? the time is $time .
    ~looks_like? it is $time .

%gotPrice
    ~looks_like? the price of $asset is ~currently? $price .
    ~looks_like? $asset is ~currently? $price .
    ~looks_like? $asset is $price ~now? .

%gotWeather
    ~looks_like? $location is ~currently? $temperature with $conditions .
    ~looks_like? the $location $key is ~currently? $value .
    ~looks_like? the $key of $location is ~currently? $value .

~looks_like
    looks like
    it seems that

~currently
    currently

~now
    right now
    at the moment

~ok
    ok,
    sure,
"""

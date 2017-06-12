module.exports = grammar = """
%fallback
    I'm not sure what happened.
    Sorry I think I'm having a mental breakdown.

%dontknow
    I didn't catch that.
    I don't understand.
    I don't ~understand ~what_you_said .
    Not sure ~what_you_said .
    What?
    Huh?

~understand
    understand
    get
    know
    know how to parse

~what_you_said
    what you said
    what you're saying
    what you're trying to say
    what you're talking about
    what that means

%greeting
    ~greeting $sender !
    ~greeting .

~greeting
    Hi
    Oh hai
    Hey there
    Hello

%farewell
    ~farewell $sender !
    ~farewell .

~farewell
    Bye 
    Goodbye
    Talk to you later
    See you later

%howareyou
    I'm ~good .

~good
    good
    pretty good
    fine
    great
    just existing here
    perfectly ok

%thanks
    You're welcome.
    You are ~very? welcome.
    No, thank you.
    My pleasure.

%insult
    Lol ok .
    I'm sorry to hear that .
    Bless your heart .
    Lol ok $sender .
    I'm sorry to hear that $sender .
    Bless your heart $sender .

~very
    very
    extremely
    so

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
    ~looks_like? $asset is ~currently? $price , with a 24h volume of $volume on $market .
    ~looks_like? $asset is $price ~now? , and the 24h volume is $volume on $market .
    ~looks_like? $asset is $price ~now? . The 24h volume on $market is $volume .
    ~looks_like? $asset is $price ~now? .

%gotWeather
    ~looks_like? $location is ~currently? $temperature with $conditions .
    ~looks_like? the $location $key is ~currently? $value .
    ~looks_like? the $key of $location is ~currently? $value .

~looks_like
    looks like
    seems like
    it looks like
    it seems that
    it seems
    it appears
    apparently
    from what I can tell
    according to my records
    according to the internet

~currently
    currently

~now
    right now
    at the moment

~ok
    ok,
    sure,
"""

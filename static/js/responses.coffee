nalgene = require 'nalgene'

grammar = nalgene.parse '''
%
    I did a thing
'''

console.log nalgene.generate grammar

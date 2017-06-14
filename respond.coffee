nalgene = require '../nalgene-js/src'
{asSentence} = require '../nalgene-js/src/helpers'
grammar = nalgene.parse require './grammar'

# entry = '%response'
# context = [
#     '%sequence', [
#         '%action', [
#             '%setLightState', [
#                 '$light_name', 'kitchen light'
#                 '$state', 'on'
#             ]
#         ],
#         '%action', [
#             '%getLightState', [
#                 '$light_name', 'living room light'
#                 '$state', 'off'
#             ]
#         ],
#         '%action', [
#             '%getPrice', [
#                 '$asset', 'bitcoin',
#                 '$price', '$3,355.42',
#                 '$volume', '$34,424,355.42',
#                 '$market', 'GDAX'
#             ]
#         ]
#     ]
# ]

respond = (context) ->
    body = nalgene.generate grammar, '%response', context
    body = asSentence body
    console.log '[respond]', body
    return body
module.exports = respond

# Description:
#   Allows Hubot to do mathematics.
#
# Commands:
#   hubot convert <expression> to <units> - Convert expression to given units.
#   == <expression> - Calculate the given expression
module.exports = (robot) ->
  robot.respond /(?:convert) (.*)/i, (msg) ->
    doMath msg, msg.match[1]

  robot.hear /^==\s*(.*)/i, (msg) ->
    doMath msg, msg.match[1]

doMath = (msg, query) ->
    msg
      .http('https://www.google.com/ig/calculator')
      .query
        hl: 'en'
        q: query
      .headers
        'Accept-Language': 'en-us,en;q=0.5',
        'Accept-Charset': 'utf-8',
        'User-Agent': "Mozilla/5.0 (X11; Linux x86_64; rv:2.0.1) Gecko/20100101 Firefox/4.0.1"
      .get() (err, res, body) ->
        # Response includes non-string keys, so we can't use JSON.parse here.
        json = eval("(#{body})")
        msg.send json.rhs || 'Could not compute.'
    

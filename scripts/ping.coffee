# Description:
#   Utility commands surrounding Hubot uptime.
#
# Commands:
#   hubot ping - Reply with pong
#   hubot echo <text> - Reply back with <text>
#   hubot time - Reply with current time
#   hubot die - End hubot process

module.exports = (robot) ->
  robot.respond /PING$/i, (msg) ->
    msg.send "PONG"
  
  # Wtf? Really?
  #robot.respond /ECHO (.*)$/i, (msg) ->
  #  msg.send msg.match[1]

  robot.respond /TIME$/i, (msg) ->
    msg.send "Server time is: #{new Date()}"

  robot.respond /DIE$/i, (msg) ->
    if robot.Auth.hasRole(msg.message.user.name,'bot master')
        msg.send "Goodbye, cruel world."
        setTimeout (-> process.exit 0), 500
    else
        msg.reply msg.random [
            "Bite me", 
            "You first", 
            "Ricky told me to randomize my permission denied messages. This is one of them.", 
            "Nope", 
            "Go to hell",
            "I don't think so",
            "I'd rather not",
            "You're not the boss of me",
            "What now?",
            "DIAF",
            "Not right now"
            ]


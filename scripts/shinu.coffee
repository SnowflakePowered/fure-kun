module.exports = (robot) ->
  robot.hear /shinde imashita/i, (msg) ->
    msg.send "shinde inai yo!"

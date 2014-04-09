module.exports = (robot) ->
  robot.respond /pack up the tent/i, (msg) ->
    msg.send("Terminating app servers.... done")
    msg.send("sending TRUNCATE USERS to db master....    done")
    msg.send("Termininating master db server....      done")
    msg.send("Deleting backups.....       done")
    msg.send("Finished killing business.  Have a nice day!")

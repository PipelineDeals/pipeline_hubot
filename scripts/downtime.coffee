module.exports = (robot) ->
  robot.respond /pack up the tent/i, (msg) ->
    msg.send("Terminating app servers.... done")
    f1 = -> msg.send("sending TRUNCATE USERS to db master....    done")
    setTimeout(f1, 1000)
    f2 = -> msg.send("Termininating master db server....      done")
    setTimeout(f2, 3000)
    f3 = -> msg.send("Deleting backups.....       done")
    setTimeout(f3, 5000)
    f4 = -> msg.send("Finished killing business.  Have a nice day!")
    setTimeout(f4, 6000)

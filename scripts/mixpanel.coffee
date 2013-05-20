# mixpanel me - Receive Mixpanel stats

# Description:
#   Mixpanel gets stats from a bridge API
#
# Dependencies:
#   None
#
# Configuration:
#   None
#
# Commands:
#   hubot mixpanel me - Receive mixpanel stats

module.exports = (robot) ->

  robot.respond /mixpanel me/i, (msg) ->
    url = process.env.MIXPANEL_API
    msg.http(url)
      .get() (err, res, body) ->
        stats = JSON.parse(body)
        msg.send "PAID\nseats created: #{stats.paid.seats_created}\nseats lost: #{stats.paid.seats_lost}\n\n
TRIAL\nseats created: #{stats.trial.seats_created}\nseats lost: #{stats.trial.seats_lost}"

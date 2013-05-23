# Description:
#   A module to query the Papertrail API
#
# Dependencies:
#   None
#
# Configuration:
#   HUBOT_PAPERTRAIL_API_TOKEN - find this in Profile -> API Token
#
# Commands:
#   hubot papertrail <query> - Search papertrail
#
# Author:
#   brandonhilkert
#

url  = 'https://papertrailapp.com/api/v1/'
api_token = process.env.HUBOT_PAPERTRAIL_API_TOKEN

search = (msg, query, callback) ->
  path = 'events/search.json?q='
  msg.http("#{url}#{path}#{query}")
    .headers("X-Papertrail-Token": api_token)
    .get() (err, res, body) ->
      callback(err, res, body)

module.exports = (robot) ->
  robot.respond /papertrail( (.*))?/i, (msg) ->
    query = msg.match[2]
    search msg, query, (err, res, body) ->
      response = JSON.parse body
      events = ""
      for event in response.events
        events += "#{event.message}\n"

      msg.send events


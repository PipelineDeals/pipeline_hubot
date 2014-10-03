# Description:
#   A module to aid in PipelineDeal's deploys
#
# Dependencies:
#   None
#
# Configuration:
#   DEPLOYMANAGER_TOKEN - An access token for PLD deploy manager
#
# Commands:
#   hubot deploy status - Responds with the deploy status of each app
#   hubot deploy pld:status - Responds with the deploy status
#   hubot deploy pld:build - Creates the servers for a deploy
#   hubot deploy pld:deploy - Sends the deploy out the door
#   hubot deploy pld:rollback - Creates the servers for a build
#   hubot deploy pld:cleanup - Creates the servers for a build
#
# Author:
#   brandonhilkert
#

_ = require("underscore")
deploymanager_token = process.env.DEPLOYMANAGER_TOKEN
deploymanager_url  = "http://deploymanager.pipelinedeals.com/api"

module.exports = (robot) ->
  robot.respond /deploy( (.*))?/i, (msg) ->
    command = msg.match[2]
    if command is "status"
      statusRequest(msg)
    else
      commandRequest(command, msg)

  ######################################
  # Utility functions
  ######################################
  statusRequest = (msg) ->
    msg.http(commandUrl("status")).get() (err, res, body) ->
      json = JSON.parse body
      _.each json, (value, key) ->
        msg.send "#{key}: #{value}"

  commandRequest = (command, msg) ->
    msg.http(commandUrl(command)).post() (err, res, body) ->
      json = JSON.parse body
      msg.send json.message

  commandUrl = (command) ->
    "#{deploymanager_url}/#{command}?token=#{deploymanager_token}"

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
#   hubot deploy status - Responds with the deploy status
#   hubot deploy build - Creates the servers for a deploy
#   hubot deploy update - Updates the built deploy servers
#   hubot deploy deploy - Sends the deploy out the door
#   hubot deploy rollback - Creates the servers for a build
#   hubot deploy cleanup - Creates the servers for a build
#
# Author:
#   brandonhilkert
#

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
      Object.keys(json).forEach (key) ->
        msg.send "#{json[key]}"

  commandRequest = (command, msg) ->
    msg.http(commandUrl(command)).post() (err, res, body) ->
      json = JSON.parse body
      msg.send json.message

  commandUrl = (command) ->
    "#{deploymanager_url}/#{command}?token=#{deploymanager_token}"

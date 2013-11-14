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
      statusRequest
    else
      commandRequest(command)

  ######################################
  # Utility functions
  ######################################
  statusRequest = (msg) ->
    msg.http("#{deploymanager_url}/status").get() (err, res, body) ->
      json = JSON.parse body
      msg.send("Deploy status: #{json.message}")

  commandRequest = (command, callback) ->
    msg.http("#{deploymanager_url}/#{command}").post() (err, res, body) ->
      json = JSON.parse body
      msg.send("Gettin' to work: #{json.message}")

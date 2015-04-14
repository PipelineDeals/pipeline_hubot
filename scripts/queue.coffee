# Description:
#   A module to get stats about PipelineDeal's queue servers
#
# Dependencies:
#   None
#
# Configuration:
#   DEPLOYMANAGER_TOKEN - An access token for PLD deploy manager
#
# Commands:
#   hubot queue stats - Responds with the stats for the queue servers
#
# Author:
#   brandonhilkert
#

deploymanager_token = process.env.DEPLOYMANAGER_TOKEN
deploymanager_url  = "https://deployer.pipelinedeals.com/api"

module.exports = (robot) ->
  robot.respond /queue stats/i, (msg) ->
    msg.http(queueStatsUrl("old-queue-server")).get() (err, res, body) ->
    msg.http(queueStatsUrl("hot-queue-server")).get() (err, res, body) ->

  ######################################
  # Utility functions
  ######################################

  queueStatsUrl = (role) ->
    "#{deploymanager_url}/queue/#{role}?token=#{deploymanager_token}"


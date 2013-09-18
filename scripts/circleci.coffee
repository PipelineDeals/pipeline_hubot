# Description:
#   A module to assist in PipelineDeal's circlci build status
#
# Dependencies:
#   None
#
# Configuration:
#   HUBOT_CIRCLECI_TOKEN
#
# Commands:
#   hubot build status <branch> - Prints the build status of the latest build in that branch
#
# Author:
#   brandonhilkert
#

circleci_token = process.env.HUBOT_CIRCLECI_TOKEN

module.exports = (robot) ->
  robot.respond /build status (.*)/i, (msg) ->
    branch = msg.match[1]
    circleci_api_url = "https://circleci.com/api/v1/project/PipelineDeals/pipeline_deals/tree/#{branch}?circle-token=#{circleci_token}"
    msg.http(circleci_api_url)
      .get() (err, res, body) ->
        response = JSON.parse(body)
        msg.send response[0].status



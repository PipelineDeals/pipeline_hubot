# Description:
#   A module to assist in PipelineDeal's development workflow
#
# Dependencies:
#   None
#
# Configuration:
#   HUBOT_GITHUB_ACCESS_TOKEN - An access token for a Github user that will reassign PRs
#   HUBOT_GITHUB_QA_USERNAME - A Github username that PR's should be reassigned to
#   HUBOT_FOGBUGZ_HOST - The host URL of the Fogbugz resource
#   HUBOT_FOGBUGZ_TOKEN - A Fogbugz API token used to resolve open tickets
#
# Commands:
#   hubot pr accept <pr number> - Accepts a PR and reassigns to QA
#   hubot pr merge <pr number> - Merges a PR
#
# Author:
#   brandonhilkert
#

github_access_token = process.env.HUBOT_GITHUB_ACCESS_TOKEN
github_qa_username = process.env.HUBOT_GITHUB_QA_USERNAME

module.exports = (robot) ->
  robot.respond /pr accept (.*)?/i, (msg) ->
    number = msg.match[1]
    url = "https://api.github.com/repos/PipelineDeals/pipeline_deals/issues/#{number}?access_token=#{github_access_token}"
    payload = JSON.stringify({assignee: github_qa_username})
    msg.http(url)
      .post(payload) (err, res, body) ->
        response = JSON.parse body
        if response.number
          msg.send "Assigned <a href=#{response.pull_request.html_url}>##{response.number}</a> to @#{github_qa_username}"
        else
          msg.send response.message



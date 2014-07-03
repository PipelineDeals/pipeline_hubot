# Description:
#   PR Linker
#
# Dependencies:
#   None
#
# Configuration:
#   HUBOT_GITHUB_ACCESS_TOKEN - An access token for a Github user that can read PRs
#
# Commands:
#   PR##### - Returns title and link to PR if found
#
# Author:
#   Christopher David Yudichak
#
# Example:
#   (user)  > What the status of PR123?
#   (hubot) > PR #123: make new business cards work on legacy agenda
#   (hubot) > https://github.com/PipelineDeals/pipeline_deals/pull/123

class PrLinker
  githubAccessToken: process.env.HUBOT_GITHUB_ACCESS_TOKEN
  githubApiUrl:      'https://api.github.com/repos'
  githubRepo:        'PipelineDeals/pipeline_deals'

  constructor: (@robot, @msg) ->

  run: (prNum) ->
    @robot.http(@githubPrUrl(prNum)).get() (err, res, body) =>
      if res.statusCode == 200
        @handleSuccess(body)
      else
        @handleFailure(prNum)

  githubPrUrl: (prNum) ->
    "#{@githubApiUrl}/#{@githubRepo}/pulls/#{prNum}?access_token=#{@githubAccessToken}"

  handleSuccess: (body) ->
    pr = JSON.parse body
    @msg.send "PR ##{pr.number}: #{pr.title}"
    @msg.send pr.html_url

  handleFailure: (prNum) ->
    @msg.send "Couldn't find a PR ##{prNum}"

module.exports = (robot) ->
  robot.hear /(.*PR#?\d+.*)/i, (msg) ->
    linker = new PrLinker(robot, msg)
    line = msg.match[1]
    for substr in line.match(/PR#?\d+/gi)
      pr_number = substr.match(/PR#?(\d+)/i)[1]
      linker.run(pr_number)

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
#   `PRnum` or `repo_name#num` - Returns title and link to PR if found
#
# Author:
#   Christopher David Yudichak
#
# Example:
#   (user)  > What the status of pipeline_deals/123?
#   (hubot) > pipeline_deals/123: make new business cards work on legacy agenda
#   (hubot) > https://github.com/PipelineDeals/pipeline_deals/pull/123

class PrLinker
  githubAccessToken: process.env.HUBOT_GITHUB_ACCESS_TOKEN
  githubApiUrl:      'https://api.github.com/repos'
  githubOrg:        'PipelineDeals'

  constructor: (@robot, @msg) ->

  run: (repo, prNum) ->
    @robot.http(@githubPrUrl(repo, prNum)).get() (err, res, body) =>
      if res.statusCode == 200
        @handleSuccess(repo, body)

  githubPrUrl: (repo, prNum) ->
    "#{@githubApiUrl}/#{@githubOrg}/#{repo}/pulls/#{prNum}?access_token=#{@githubAccessToken}"

  handleSuccess: (repo, body) ->
    pr = JSON.parse body
    @msg.send pr.html_url

module.exports = (robot) ->
  robot.hear /(.*(PR#?|[a-z_\-]+#)\d{1,5}.*)/i, (msg) ->
    linker = new PrLinker(robot, msg)
    line = msg.match[1]
    for substr in line.match(/(PR#?|[a-z_\-]+#)\d+/gi)
      matchdata = substr.match(/(PR#?|[a-z_\-]+#)(\d+)/i)
      repo = matchdata[1].replace('#', '')
      repo = 'pipeline_deals' if repo.match(/PR#?/)
      pr_number = matchdata[2]
      linker.run(repo, pr_number)

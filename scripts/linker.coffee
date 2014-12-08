# Description:
#   Linkers
#
# Dependencies:
#   None
#
# Commands:
#   `pr:repo_name/###` - Returns title and link to PR if found
#   `jira:XX-###` - Returns title and link to Jira ticket if found
#
# Author:
#   Christopher David Yudichak
#
# Example:
#   (user)  > Tell me something about jira:MBL-123, jira:MBL-1234, and pr:pipeline_google/123
#   (hubot) > pipeline_google/123: [PLD-1062] ignore private series
#   (hubot) > https://github.com/PipelineDeals/pipeline_google/pull/123
#   (hubot) > MBL-123: Pro Claims Recovery, LLC (21886) - Custom fields section missing for person profile page
#   (hubot) > https://pipelinedeals.atlassian.net/browse/MBL-123
#   (hubot) > MBL-1234: User can't see people linked to deal he owns
#   (hubot) > https://pipelinedeals.atlassian.net/browse/MBL-1234

class PrLinker
  githubAccessToken: process.env.HUBOT_GITHUB_ACCESS_TOKEN
  githubApiUrl:      'https://api.github.com/repos'
  githubOrg:         'PipelineDeals'

  constructor: (@robot, @msg) ->

  run: (prString) ->
    data = prString.split('/')
    repo = data[0]
    prNum = data[1]
    @robot.http(@githubPrUrl(repo, prNum)).get() (err, res, body) =>
      if res.statusCode == 200
        @handleSuccess(repo, body)

  githubPrUrl: (repo, prNum) ->
    "#{@githubApiUrl}/#{@githubOrg}/#{repo}/pulls/#{prNum}?access_token=#{@githubAccessToken}"

  handleSuccess: (repo, body) ->
    pr = JSON.parse body
    @msg.send "#{repo}/#{pr.number}: #{pr.title}"
    @msg.send pr.html_url

class JiraLinker
  jiraToken: process.env.JIRA_TOKEN
  jiraBaseUrl: 'https://pipelinedeals.atlassian.net'
  jiraApiPath: '/rest/api/2'
  jiraBrowsePath: '/browse'

  constructor: (@robot, @msg) ->

  run: (ticketString) ->
    @robot.http(@jiraTicketApiUrl(ticketString)).
      headers("Authorization": "Basic #{@jiraToken}", "Content-Type": "application/json").
      get() (err, res, body) =>
        if res.statusCode == 200
          @handleSuccess(ticketString, body)

  jiraTicketApiUrl: (ticketString) ->
    "#{@jiraBaseUrl}#{@jiraApiPath}/issue/#{ticketString}"

  jiraTicketBrowseUrl: (ticketString) ->
    "#{@jiraBaseUrl}#{@jiraBrowsePath}/#{ticketString}"

  handleSuccess: (ticketString, body) ->
    ticket = JSON.parse(body)
    @msg.send "#{ticketString}: #{ticket.fields.summary}"
    @msg.send @jiraTicketBrowseUrl(ticket.key)

module.exports = (robot) ->
  robot.hear /(\w+):([\w-/]+)/g, (msg) ->
    for linkable in msg.match
      data = linkable.match(/(\w+):([\w-/]+)/)
      type = data[1]
      number = data[2]

      linker = switch type
        when 'pr' then new PrLinker(robot, msg)
        when 'jira' then new JiraLinker(robot, msg)
      linker.run(number)


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
fogbugz_host = process.env.HUBOT_FOGBUGZ_HOST
fogbugz_token = process.env.HUBOT_FOGBUGZ_TOKEN

module.exports = (robot) ->
  robot.respond /pr accept (\d+)/i, (msg) ->
    pr_number = msg.match[1]

    # Add random approval as comment on the PR
    github_comment_api_url = "https://api.github.com/repos/PipelineDeals/pipeline_deals/issues/#{pr_number}/comments?access_token=#{github_access_token}"
    emojis = ["+1", "smile", "relieved", "sparkles", "star2", "heart", "notes", "ok_hand", "clap", "raised_hands", "dancer", "kiss", "100", "ship", "shipit", "beer", "high_heel", "moneybag", "zap", "sunny", "dolphin"]
    emoji = emojis[Math.floor(Math.random() * emojis.length)]
    payload = JSON.stringify({ body: ":#{emoji}:" })
    msg.http(github_comment_api_url).post(payload)

    # Assign PR to QA
    github_issue_api_url = "https://api.github.com/repos/PipelineDeals/pipeline_deals/issues/#{pr_number}?access_token=#{github_access_token}"
    payload = JSON.stringify({ assignee: github_qa_username })
    msg.http(github_issue_api_url).post(payload) (err, res, body) ->
      response = JSON.parse body

      # if response.number
      #   msg.send "Assigned <a href='#{response.pull_request.html_url}'>##{response.number}</a> to @#{github_qa_username}"
      # else
      #   msg.send response.message

  robot.respond /pr deadbeats/i, (msg) ->
    parseIssues = (issues) ->
      parsedIssues = []
      now = new Date()
      millisecondsPerDay = 1000 * 60 * 60 * 24;
      for issue in issues
        diff = now - (new Date(issue.created_at))
        daysOld = diff / millisecondsPerDay

        oldIssue = {}
        oldIssue.number = issue.number
        oldIssue.title = issue.title
        if issue.assignee
          oldIssue.owner = issue.assignee.login
        else
          oldIssue.owner = "UNASSIGNED"
        oldIssue.href = issue.html_url
        oldIssue.daysOld = Math.round(daysOld)
        if daysOld >= 1
          parsedIssues.push(oldIssue)
      parsedIssues

    github_issue_api_url = "https://api.github.com/repos/PipelineDeals/pipeline_deals/issues?access_token=#{github_access_token}"
    msg.http(github_issue_api_url).get() (err, res, body) ->
      issues = JSON.parse(body)
      issues = parseIssues(issues)
      for issue in issues
        msg.send "PR #{issue.number} is #{issue.daysOld} days old, owned by #{issue.owner} -- #{issue.href}"
      if issues.length > 5
        msg.send "That's a lot of issues, and a lot of deadbeats.  Get your act together, fools!"
      else
        msg.send "Nice work managing those PRs!!"

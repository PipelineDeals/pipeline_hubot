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

jira_token = process.env.JIRA_TOKEN

module.exports = (robot) ->
  robot.respond /pr dev accept (\d+)/i, (msg) ->
    prNum = msg.match[1]
    user = msg.message.user.name
    devAcceptPR(user, prNum, msg)

  robot.respond /pr qa accept (\d+)/i, (msg) ->
    prNum = msg.match[1]
    user = msg.message.user.name
    qAAcceptPR(user, prNum, msg)

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
        if daysOld >= 1 and oldIssue.title.indexOf("WIP") == -1
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

  ######################################
  # Utility functions
  ######################################
  devAcceptPR = (user, prNum, msg) ->
    commentOnPR(user, prNum, msg)
    assignPRtoQA(prNum, msg)
    msg.send("The ticket has been accepted by the Devs... yup.")

  qAAcceptPR = (user, prNum, msg) ->
    commentOnPR("#{user} (QA)", prNum, msg)
    markTicketAsPeerReviewed(prNum, msg)
    msg.send("The ticket has been accepted by QA.")

  commentOnPR = (user, prNum, msg) ->
    github_comment_api_url = "https://api.github.com/repos/PipelineDeals/pipeline_deals/issues/#{prNum}/comments?access_token=#{github_access_token}"
    payload = JSON.stringify({ body: "#{user} approves!  :#{getEmoji()}:" })
    msg.http(github_comment_api_url).post(payload)

  assignPRtoQA = (prNum, msg) ->
    github_issue_api_url = "https://api.github.com/repos/PipelineDeals/pipeline_deals/issues/#{prNum}?access_token=#{github_access_token}"
    payload = JSON.stringify({ assignee: github_qa_username })
    msg.http(github_issue_api_url).post(payload) (err, res, body) ->
      response = JSON.parse body

  markTicketAsPeerReviewed = (prNum, msg) ->
    github_issue_api_url = "https://api.github.com/repos/PipelineDeals/pipeline_deals/issues/#{prNum}?access_token=#{github_access_token}"
    msg.http(github_issue_api_url).get(github_issue_api_url) (err, res, body) ->
      json = JSON.parse body
      title = json['title']
      re = /\[.*?\]/
      ticketNum = re.exec(title)[0].replace('#','').replace('[','').replace(']','')
      payload = '{"transition": {"id":"751"}}'
      console.log "ticketNum = ", ticketNum
      msg.
        http("https://pipelinedeals.atlassian.net/rest/api/2/issue/#{ticketNum}/transitions").
        headers("Authorization": jira_token, Content-Type": "application/json").
        post(payload) (err, res, body) ->
          console.log "err = ", err

  getEmoji = ->
    emojis = ["+1", "smile", "relieved", "sparkles", "star2", "heart", "notes", "ok_hand", "clap", "raised_hands", "dancer", "kiss", "100", "ship", "shipit", "beer", "high_heel", "moneybag", "zap", "sunny", "dolphin"]
    emojis[Math.floor(Math.random() * emojis.length)]

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
#   hubot pr dev accept <pr number> - Accepts a PR and reassigns to QA
#   hubot pr qa accept <pr number> - QA accepts pr
#   hubot business owner approve <jira ticket> - Business owner approve a ticket
#   hubot pr merge <pr number> - Merge a PR and update the jira ticket
#   hubot pr merge <pr number> - Merges a PR
#   hubot github release - Tag the release in github, write release notes
#   hubot close released tickets - Close out tickets that have the current release num
#
# Author:
#   brandonhilkert
#

_ = require("underscore")
github_access_token = process.env.HUBOT_GITHUB_ACCESS_TOKEN
github_qa_username = process.env.HUBOT_GITHUB_QA_USERNAME

fogbugz_host = process.env.HUBOT_FOGBUGZ_HOST
fogbugz_token = process.env.HUBOT_FOGBUGZ_TOKEN

jira_token = process.env.JIRA_TOKEN
deploymanager_token = process.env.DEPLOYMANAGER_TOKEN
deploymanager_url  = "http://deploymanager.pipelinedeals.com"

JiraPeerReviewed = 751
JiraClosed = 781
JiraBusinessOwnerApproved = 771
JiraPRCustomField = "customfield_10400"
JiraReleaseVersionCustomField = "customfield_10401"
JiraDeployableStatus = 10011 # the ticket is in business owner approved atatus
JiraBusinesOwnerApprovableStatus = 10010

GithubDevApprovedLabel = "Dev peer reviewed"
GithubQAApprovedLabel = "QA approved"
GithubBusinessOwnerApprovedLabel = "Business owner approved"

GithubTestFailure = 'failure'
GithubTestSuccess = 'success'
GithubTestPending = 'pending'

ReleaseVersion = null

module.exports = (robot) ->

  robot.respond /pr dev accept (\d+)/i, (msg) ->
    prNum = msg.match[1]
    getBranchStatus prNum, msg, (status) ->
      switch status
        when GithubTestFailure then msg.send "Can't accept PR, as the latest specs failed"
        when GithubTestPending then msg.send "Whoa there partner, wait till the tests finish running!"
        when null then msg.send "Looks like things are backed up.  Please wait until circleci runs on this branch."
        when GithubTestSuccess
          devAcceptPR(prNum, msg)
          labelPr(prNum, GithubDevApprovedLabel, msg)

  robot.respond /pr qa accept (\d+)/i, (msg) ->
    prNum = msg.match[1]
    ticketCanBePeerReviewed = ->
      getBranchStatus prNum, msg, (status) ->
        switch status
          when GithubTestFailure then msg.send "Can't accept PR, as the latest specs failed"
          when GithubTestPending then msg.send "Whoa there partner, wait till the tests finish running!"
          when null then msg.send "Looks like things are backed up.  Please wait until circleci runs on this branch."
          when GithubTestSuccess
            qAAcceptPR(prNum, msg)
            labelPr(prNum, GithubQAApprovedLabel, msg)
    ticketCannotBePeerReviewed = ->
      msg.send("I couldn't update the jira ticket, because the ticket's state cannot transition to peer reviewed.  That means one of the following:  1) The ticket is already in the peer reviewed state, 2) It is not marked as resolved, 3) it is marked as closed or deployed.  However, I will update the github PR.");
      qAAcceptPR(prNum, msg)
      labelPr(prNum, GithubQAApprovedLabel, msg)
    qAAcceptable(prNum, ticketCanBePeerReviewed, ticketCannotBePeerReviewed, msg)

  robot.respond /pr merge (\d+)/i, (msg) ->
    prNum = msg.match[1]

    getDeployManagerStatus (status) ->
      if status != 'ready'
        msg.send("No merging until the deploy has been cleaned up!");
      else
        getJiraTicketFromPR prNum, msg, (ticketNum) ->
          getTicketStatus ticketNum, msg, (status) ->
            if status == null
              msg.send("I could not find the jira ticket!")
              return
            if status.toString() == JiraDeployableStatus.toString()
              # close the jira ticket and set the release version
              work = (ticketNum) ->
                setJiraTicketReleaseVersion(ticketNum, msg)
                #transitionTicket(ticketNum, JiraClosed, msg) # not until we move to CD
              getJiraTicketFromPR(prNum, msg, work)

              # put deploy version in PR and merge it
              getReleaseVersion msg, (version) ->
                commentOnPR(prNum, "Release version: #{version}", msg)
                mergePR(prNum, msg)
                msg.send("The PR has been merged and the ticket has been updated.")
            else
              msg.send("This ticket is not mergeable, because the business owner has not yet approved it.")

  robot.respond /pr force merge (\d+)/i, (msg) ->
    prNum = msg.match[1]
    getReleaseVersion msg, (version) ->
      commentOnPR(prNum, "Release version: #{version}", msg)
      mergePR(prNum, msg)
      msg.send("The PR has been merged.")
      msg.send("I like a man who takes charge!")

  robot.respond /boa constrictor/i, (msg) ->
    msg.send "ITS SNAKEY TIME!!"
    msg.send "hubot image me snakes"

  robot.respond /boa (.*)/i, (msg) -> 
    ticket = msg.match[1]
    businessOwnerApprove(ticket, msg)

  robot.respond /business owner approve (.*)/i, (msg) ->
    ticket = msg.match[1]
    businessOwnerApprove(ticket, msg)

  businessOwnerApprove = (ticket, msg) ->
    getTicketStatus ticket, msg, (status) ->
      if status == null
        msg.send("I could not find the jira ticket!")
        return
      if status.toString() == JiraBusinesOwnerApprovableStatus.toString()
        transitionTicket(ticket, JiraBusinessOwnerApproved, msg)
        work = (prNum) ->
          return if prNum == null
          commentOnPR(prNum, approveComment("#{msg.message.user.name} (Business Owner)"), msg)
          labelPr(prNum, GithubBusinessOwnerApprovedLabel, msg)
        getPrFromJiraTicket(ticket, msg, work)
      else
        msg.send("This ticket cannot be approved by the business owner, as it has not been accepted by QA yet.")

  robot.respond /get release version/i, (msg) ->
    getReleaseVersion msg, (version) ->
      msg.send("version is #{version}")

  ######################################
  # Utility functions
  ######################################

  devAcceptPR = (prNum, msg) ->
    commentOnPR(prNum, approveComment(msg.message.user.name), msg)
    assignPRtoQA(prNum, msg)
    msg.send("#{linkToPr(prNum)} has been accepted by the devs. (#{getHipchatEmoji()})")

  qAAcceptable = (prNum, successFn, failFn, msg) ->
    getJiraTicketFromPR prNum, msg, (ticketNum) -> ticketTransitionableTo(ticketNum, JiraPeerReviewed, successFn, failFn, msg)

  qAAcceptPR = (prNum, msg) ->
    commentOnPR(prNum, approveComment("#{msg.message.user.name} (QA)"), msg)
    markTicketAsPeerReviewed(prNum, msg)
    msg.send("#{linkToPr(prNum)} has been accepted by QA. (#{getHipchatEmoji()})")

  labelPr = (prNum, label, msg) ->
    getPRLabels prNum, msg, (existingLabels) ->
      url = "https://api.github.com/repos/PipelineDeals/pipeline_deals/issues/#{prNum}/labels?access_token=#{github_access_token}"
      existingLabels.unshift(label)
      msg.http(url).post(JSON.stringify(existingLabels)) (err, res, body) ->
        console.log err

  getPRLabels = (prNum, msg, cb) ->
    url = "https://api.github.com/repos/PipelineDeals/pipeline_deals/issues/#{prNum}/labels?access_token=#{github_access_token}"
    msg.http(url).get() (err, res, body) ->
      existingLabels = JSON.parse body
      console.log existingLabels
      existingLabels = existingLabels.map (label) -> label.name
      cb(existingLabels) if cb

  commentOnPR = (prNum, comment, msg) ->
    github_comment_api_url = "https://api.github.com/repos/PipelineDeals/pipeline_deals/issues/#{prNum}/comments?access_token=#{github_access_token}"
    payload = JSON.stringify({ body: comment})
    msg.http(github_comment_api_url).post(payload)

  getBranchStatus = (prNum, msg, cb) ->
    url = "https://api.github.com/repos/PipelineDeals/pipeline_deals/pulls/#{prNum}?access_token=#{github_access_token}"
    msg.http(url).get() (err, res, body) ->
      body = JSON.parse(body)
      msg.http("#{body.statuses_url}?access_token=#{github_access_token}").get() (err, res, body) ->
        body = JSON.parse(body)
        return null if body[0] == undefined
        cb(body[0].state)

  approveComment = (user) -> "#{user} approves!  :#{getGithubEmoji()}:"

  assignPRtoQA = (prNum, msg) ->
    github_issue_api_url = "https://api.github.com/repos/PipelineDeals/pipeline_deals/issues/#{prNum}?access_token=#{github_access_token}"
    payload = JSON.stringify({ assignee: github_qa_username })
    msg.http(github_issue_api_url).post(payload) (err, res, body) ->
      response = JSON.parse body

  getJiraTicketFromPR = (prNum, msg, cb) ->
    github_issue_api_url = "https://api.github.com/repos/PipelineDeals/pipeline_deals/issues/#{prNum}?access_token=#{github_access_token}"
    msg.http(github_issue_api_url).get(github_issue_api_url) (err, res, body) ->
      json = JSON.parse body
      title = json['title']
      matches = title.match(/\[.*?\]/g)
      return cb(null) if matches == null
      _.each matches, (ticket) ->
        ticket = ticket.replace('#','').replace('[','').replace(']','')
        cb(ticket)

  getPrFromJiraTicket= (ticket, msg, cb) ->
    msg.
      http("https://pipelinedeals.atlassian.net/rest/api/2/issue/#{ticket}").
      headers("Authorization": "Basic #{jira_token}", "Content-Type": "application/json").
      get() (err, res, body) ->
        json = JSON.parse(body)
        url = json.fields[JiraPRCustomField]
        if url
          cb(url.split('/').reverse()[0])
        else
          cb(null)

  markTicketAsPeerReviewed = (prNum, msg) ->
    github_issue_api_url = "https://api.github.com/repos/PipelineDeals/pipeline_deals/issues/#{prNum}?access_token=#{github_access_token}"
    work = (ticketNum) ->
      addPrURLToTicket(ticketNum, prNum, msg)
      transitionTicket(ticketNum, JiraPeerReviewed, msg)
    getJiraTicketFromPR(prNum, msg, work)

  addPrURLToTicket = (ticketNum, prNum, msg) ->
    githubUrl = "https://github.com/PipelineDeals/pipeline_deals/pull/#{prNum}"
    fields = {}
    fields[JiraPRCustomField] = githubUrl
    payload = JSON.stringify({ fields: fields})
    msg.
      http("https://pipelinedeals.atlassian.net/rest/api/2/issue/#{ticketNum}").
      headers("Authorization": "Basic #{jira_token}", "Content-Type": "application/json").
      put(payload) (err, res, body) ->
        console.log "err = ", err

  transitionTicket = (ticketNum, jiraTransitionId, msg) ->
    payload = JSON.stringify({transition:{id: jiraTransitionId}})
    msg.
      http("https://pipelinedeals.atlassian.net/rest/api/2/issue/#{ticketNum}/transitions").
      headers("Authorization": "Basic #{jira_token}", "Content-Type": "application/json").
      post(payload) (err, res, body) ->
        msg.send "Ticket #{ticketNum} has been updated."
        console.log "err = ", err

  getTicketStatus = (ticketNum, msg, cb) ->
    msg.
      http("https://pipelinedeals.atlassian.net/rest/api/2/issue/#{ticketNum}").
      headers("Authorization": "Basic #{jira_token}", "Content-Type": "application/json").
      get() (err, res, body) ->
        body = JSON.parse(body)
        if body.fields
          cb(body.fields.status.id)
        else
          cb(null)

  ticketTransitionableTo = (ticketNum, ticketId, canBeFn, cannotBeFn, msg) ->
    msg.
      http("https://pipelinedeals.atlassian.net/rest/api/2/issue/#{ticketNum}/transitions").
      headers("Authorization": "Basic #{jira_token}", "Content-Type": "application/json").
      get() (err, res, body) ->
        json = JSON.parse body
        transition = _.find json.transitions, (transition) -> transition.id == ticketId.toString()
        if transition then canBeFn() else cannotBeFn()

  mergePR = (prNum, msg) ->
    github_issue_api_url = "https://api.github.com/repos/PipelineDeals/pipeline_deals/pulls/#{prNum}/merge?access_token=#{github_access_token}"
    msg.http(github_issue_api_url).put(JSON.stringify({commit_message: "Merge into master"})) (err, res, body) ->
      if JSON.parse(body).merged == true
        deleteBranch(prNum, msg)
      else
        msg.send "The PR was not merged for some reason.  The message I got was #{JSON.parse(body).message}"

  deleteBranch = (prNum, msg) ->
    url  = "https://api.github.com/repos/PipelineDeals/pipeline_deals/pulls/#{prNum}?access_token=#{github_access_token}"
    msg.http(url).get() (err, res, body) ->
      json = JSON.parse body
      branch = json.head.ref
      url  = "https://api.github.com/repos/PipelineDeals/pipeline_deals/git/refs/heads/#{branch}?access_token=#{github_access_token}"
      msg.http(url).delete() (err, res, body) -> console.log err

  setJiraTicketReleaseVersion = (ticketNum, msg) ->
    fields = {}
    getReleaseVersion msg, (version) ->
      fields[JiraReleaseVersionCustomField] = version.toString()
      payload = {"fields": fields}
      msg.
        http("https://pipelinedeals.atlassian.net/rest/api/2/issue/#{ticketNum}").
        headers("Authorization": "Basic #{jira_token}", "Content-Type": "application/json").
        put(JSON.stringify(payload)) (err, res, body) ->
          console.log "release version err = ", err
          console.log "release version body = ", body
          console.log "release version res = ", res

  getReleaseVersion = (msg, cb) ->
    msg.http("#{deploymanager_url}/version?token=#{deploymanager_token}").get() (err, res, body) ->
      cb(JSON.parse(body).version)

  getDeployManagerStatus= (msg, cb) ->
    msg.http("#{deploymanager_url}/version?token=#{deploymanager_token}").get() (err, res, body) ->
      cb(JSON.parse(body).message)

  linkToPr = (prNum) ->
    "https://github.com/PipelineDeals/pipeline_deals/pull/#{prNum}"

  getGithubEmoji = ->
    selectRandom ["+1", "smile", "relieved", "sparkles", "star2", "heart", "notes", "ok_hand", "clap", "raised_hands", "dancer", "kiss", "100", "ship", "shipit", "beer", "high_heel", "moneybag", "zap", "sunny", "dolphin"]

  getHipchatEmoji = ->
    selectRandom ["allthethings", "awthanks", "awyeah", "basket", "beer", "bunny", "cadbury", "cake", "candycorn", "caruso", "chewie", "chocobunny", "chucknorris", "coffee", "dance", "dealwithit", "hipster", "kwanzaa", "menorah", "ninja", "philosoraptor", "pbr", "present", "tree", "thumbsup", "tea", "success", "yougotitdude"]

  selectRandom = (list) ->
    list[Math.floor(Math.random() * list.length)]


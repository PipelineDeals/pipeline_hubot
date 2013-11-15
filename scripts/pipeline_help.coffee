module.exports = (robot) ->
  robot.respond /pipelinedeals help/i, (msg) ->
    resp = """
    Hubot pipelinedeals commands:
      hubot pr dev accept 1234             -- the developer accepts a commit.  The jira ticket will be updated with the github PR url.
      hubot pr qa accept 1234              -- QA accepts a commit.  The jira ticket gets moved to "Peer Reviewed"
      hubot business owner approve MBL-123 -- The business owner of the ticket approves the fix on stagemanager
      hubot set release version 3.5.xx     -- Sets the release version
      hubot get release version 3.5.xx     -- Sets the release version
      hubot pr merge 123                   -- Merge the PR into master.  Will close the jira ticket, and set its release version custom field
    """
    msg.send resp

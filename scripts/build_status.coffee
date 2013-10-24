# Description:
#   Get the build status from circleci
#
# Dependencies:
#   None
#
# Configuration:
#   CIRCLECI_API_KEY - The api token from circleci
#
# Commands:
#   hubot build status
#
# Author:
#   gammons
#

circleci_api_key = process.env.CIRCLECI_API_KEY

module.exports = (robot) ->
  #robot.respond /build status (\d+)/i, (msg) ->
  robot.respond /build status/i, (msg) ->
    branch = msg.match[1]
    getRecentBuild = (branch) ->
      branch['recent_builds'][0]

    buildOutput = (name, build) ->
      if build.outcome == 'failed'
        "#{name}:  FAILING as of build #{build.build_num} https://circleci.com/gh/PipelineDeals/pipeline_deals/#{build.build_num}\n"
      else if build.outcome == 'success'
        "#{name}:  SUCCESS as of build #{build.build_num} https://circleci.com/gh/PipelineDeals/pipeline_deals/#{build.build_num}\n"
      else if build.outcome == 'timedout'
        "#{name}:  TIMEOUT as of build #{build.build_num} https://circleci.com/gh/PipelineDeals/pipeline_deals#{build.build_num}\n"

    circleci_url = "https://circleci.com/api/v1/projects?circle-token=#{circleci_api_key}"
    msg.http(circleci_url).headers("Accept": "application/json").get() (err, res, body) ->
      branches = JSON.parse(body)[0]['branches']
      output = ''
      output += buildOutput('master', getRecentBuild(branches['master']))
      output += buildOutput('develop', getRecentBuild(branches['develop']))
      msg.send output

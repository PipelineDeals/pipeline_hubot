# Commands:
#   hubot set release version - Set the release version
#   hubot get release version <versionNum> - Get the release version
module.exports = (robot) ->

  robot.respond /set release version (.*)/i, (msg) ->
    version = msg.match[1]
    robot.brain.set('releaseVersion',version)
    msg.send "Ok, release version is #{releaseVersion()}"

  robot.respond /get release version/i, (msg) ->
    msg.send "The release version currently is #{releaseVersion()}"

  robot.respond /release version bump patch/i, (msg) ->
    release = releaseVersionArray()
    release[3] = bumpNumber(release[3])
    setReleaseFromArray(release)
    msg.send "Ok, the release version is now #{releaseVersion()}"

  robot.respond /release version bump minor/i, (msg) ->
    release = releaseVersionArray()
    release[2] = bumpNumber(release[2])
    setReleaseFromArray(release)
    msg.send "Ok, the release version is now #{releaseVersion()}"

  robot.respond /release version bump major/i, (msg) ->
    release = releaseVersionArray()
    release[1] = bumpNumber(release[1])
    setReleaseFromArray(release)
    msg.send "Ok, the release version is now #{releaseVersion()}"

  ################################
  # Utility functions
  ################################

  releaseVersion = -> robot.brain.get('releaseVersion')
  releaseVersionArray = -> robot.brain.get('releaseVersion').split('.')

  setReleaseFromArray = (arr) -> robot.brain.set('releaseVersion',arr.join('.'))

  stringWithLeadingZero = (num) -> if String(num) < 10 then "0#{String(num)}" else String(num)

  bumpNumber = (numString) ->
    numString = String(parseInt(numString) + 1)
    stringWithLeadingZero(numString)


# Description:
#   A module to assist in PipelineDeal's development workflow
#
# Dependencies:
#   None
#
# Configuration:
#   DASHBOARD_URL - URL to internal dashbaord
#   DASHBOARD_APP_KEY - Dashboard app key
#   DASHBOARD_AUTH - Dashboard auth
#
# Commands:
#   hubot c email <email> - Find users by email
#   hubot c name <name> - Find users by last name.  If 2 words sent, find by first and last name.
DashboardURL = process.env.DASHBOARD_URL
AppKey = process.env.DASHBOARD_APP_KEY
DashboardAuth = process.env.DASHBOARD_AUTH
BackendURL = process.env.BACKEND_URL

_ = require("underscore")

module.exports = (robot) ->
  robot.respond /c email (.*)/i, (msg) ->
    term = msg.match[1]
    url = "http://#{DashboardURL}/accounts/email?term=#{term}&app_key=#{AppKey}"
    msg.http(url).
      headers("Authorization": "Basic #{DashboardAuth}").
      get() (err, res, body) ->
        console.log JSON.parse(body)
        if JSON.parse(body).accounts.length > 50
          msg.send "Too many results found!"
        else
          sendResults(body, msg)

  robot.respond /c name (.*)/i, (msg) ->
    term = msg.match[1]
    url = "http://#{DashboardURL}/accounts/name?term=#{term}&app_key=#{AppKey}"
    msg.http(url).
      headers("Authorization": "Basic #{DashboardAuth}").
      get() (err, res, body) ->
        console.log JSON.parse(body)
        if JSON.parse(body).accounts.length > 50
          msg.send "Too many results found!"
        else
          sendResults(body, msg)

  sendResults = (body, msg) ->
    str = ""
    str += "Results:\n"
    _.each JSON.parse(body).accounts, (user) ->
      str += "#{user.first_name} #{user.last_name} from #{user.account_company_name} (#{user.num_users})\n"
      str += "  id: #{user.id}\n"
      str += "  SU link: #{BackendURL}/su?id=#{user.id}\n\n"
      str += "  Account link: #{BackendURL}/accounts?ss%5Baccount_id%5D=#{user.account_id}\n"
      str += "  User link: #{BackendURL}/users2/search?ss%5Buser_id%5D=#{user.id}\n"
      str += "  email: #{user.email}\n"
      str += "  account id: #{user.account_id}\n"
      str += "  account state: #{user.account_state}\n"

    msg.send str

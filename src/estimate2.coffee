# Description:
#   Sets up and allows estimation voting on a given topic. Used for sprint
#   estimation meetings and async voting.
#
# Commands:
#   hubot estimate <ticket_id> as <points> - saves estimate
#   hubot estimate team <channel>, <pivotal_project_id>, [<team_members>] - saves a team
#   estimate for <ticket_id> - lists the estimate with user names
#   estimate voters for <ticket_id> - lists the users names voted
#   estimate remove <ticket_id> - removes votes for given ticket_id
#   estimate max <voters_count> for <ticket_id> - prints the votes when the voters_count number of voters has estimated
#
# Configuration:
#   HUBOT_PIVOTAL_TOKEN
#
# Notes:
#   Estimations follow the naming convention `#{NAMESPACE}123` in redis
#
# Authors:
#   kleinjm, malkomalko, danteregis

http = require "http"
Brain = require("./brain")
EstimateTeamMsg = require("./estimate_team_msg")
charRemover = require('./char_remover')

HUBOT_PIVOTAL_TOKEN = process.env.HUBOT_PIVOTAL_TOKEN
NAMESPACE = "hubot-estimate-"
TOTAL_VOTERS = "-max-voters"
TRACKER_BASE_URL = "https://www.pivotaltracker.com/services/v5"


module.exports = (robot) ->
  brain = new Brain(robot)

  robot.respond /estimate team(.*)/i, id: 'estimate.team', (res) ->
    parsedMsg = new EstimateTeamMsg(res.match[1])
    estimateTeam(res, parsedMsg)


estimateTeam = (res, msg) ->


# Description:
#   Sets up and allows estimation voting on a given topic. Used for sprint
#   estimation meetings and async voting.
#
# Commands:
#   hubot estimate <ticket_id> as <points> - saves estimate
#   estimate for <ticket_id> - lists the estimate with user names
#   estimate voters for <ticket_id> - lists the users names voted
#   estimate remove <ticket_id> - removes votes for given ticket_id
#   estimate total <voters_count> for <ticket_id> - prints the votes when the voters_count number of voters has estimated
#
# Configuration:
#   HUBOT_PIVOTAL_TOKEN
#
# Notes:
#   Estimations follow the naming convention `#{NAMESPACE}123` in redis
#
# Author:
#   kleinjm

http = require "http"

HUBOT_PIVOTAL_TOKEN = process.env.HUBOT_PIVOTAL_TOKEN
NAMESPACE = "hubot-estimate-"
TOTAL_VOTERS = "-total-voters"
TRACKER_BASE_URL = "https://www.pivotaltracker.com/services/v5"

median = (ticket) ->
  values = (parseInt(value) for own prop, value of ticket)
  values.sort  (a, b) -> return a - b
  half = Math.floor values.length/2
  if values.length % 2
    Math.ceil values[half]
  else
    Math.ceil((values[half-1] + values[half]) / 2.0)

listVoters = (ticket, withVote = false) ->
  voters = ""
  for voter, vote of ticket
    if voters != ""
      voters = voters + ", "
    voters = voters + (if withVote then "#{voter}: #{vote}" else voter)
  voters

noEstimationMessage = (ticketId) ->
  "There is no estimation for story #{ticketId}"

estimateFor = ({ robot, res, ticketId }) ->
  ticket = robot.brain.get "#{NAMESPACE}#{ticketId}"
  if !ticket
    res.send noEstimationMessage(ticketId)
    return

  # see if votes are unanimous
  values = (parseInt(value) for own prop, value of ticket)
  allEqual = !!values.reduce((a, b) ->
    if a == b then a else NaN
  )
  points = ticket[Object.keys(ticket)[0]]
  if allEqual
    msg = "Unanimous estimation of #{points} points by #{listVoters(ticket)}"
    res.send msg
  else
    res.send "Median vote of #{median(ticket)} by #{listVoters(ticket, true)}"

  # post to pivotal tracker
  if HUBOT_PIVOTAL_TOKEN?
    updatePivotalTicket({ robot, res, ticketId, points })

updatePivotalTicket = ({ robot, res, ticketId, points }) ->
  res.send "Updating ticket ##{ticketId} with #{points} point(s)"
  data = JSON.stringify { estimate: points }
  project_id = "1539249"
  url = "#{TRACKER_BASE_URL}/projects/#{project_id}/stories/#{ticketId}"
  robot.http(url)
    .header("Content-Type", "application/json")
    .header("X-TrackerToken", HUBOT_PIVOTAL_TOKEN)
    .put(data) (err, _, body) ->
      if err
        robot.logger.debug err
      else
        response = JSON.parse body
        robot.logger.debug response
        res.send "Response from PT: #{body}"

module.exports = (robot) ->
  robot.respond /estimate (.*) as (.*)/i, id: 'estimate.estimate', (res) ->
    # tell the user what they voted for and what the vote is
    ticketId = res.match[1].trim()
    pointsTrimmed = res.match[2].trim()
    points = Number(pointsTrimmed)

    isInteger = points % 1 == 0

    if pointsTrimmed != "" && isInteger && points >= 0
      res.send "You've estimated story #{ticketId} as #{points} points"
    else
      res.send "Please enter a positive integer for your vote"
      return

    # set the key value pair for that ticket for this user
    ticket = robot.brain.get("#{NAMESPACE}#{ticketId}") || {}
    user = res.message.user.name.toLowerCase()
    ticket[user] = points
    robot.brain.set "#{NAMESPACE}#{ticketId}", ticket

    # check for max voters count
    totalVotersCount = robot.brain.get("#{NAMESPACE}#{ticketId}#{TOTAL_VOTERS}")
    return unless totalVotersCount

    # if we've reached max voters, print the estimate
    ticketVoteCount = Object.keys(ticket).length
    if ticketVoteCount >= totalVotersCount
      estimateFor({ robot, res, ticketId })

  robot.hear /estimate for (.*)/i, id: 'estimate.for', (res) ->
    # check if the ticket exists and return if not
    ticketId = res.match[1]
    estimateFor({ robot, res, ticketId })

  robot.hear /estimate voters for (.*)/i, id: 'estimate.voters-for', (res) ->
    # check if the ticket exists and return if not
    ticketId = res.match[1]
    ticket = robot.brain.get "#{NAMESPACE}#{ticketId}"
    if !ticket
      res.send noEstimationMessage(ticketId)
      return

    res.send "People who voted for #{ticketId}: #{listVoters(ticket)}"

  robot.hear /estimate remove (.*)/i, id: 'estimate.remove', (res) ->
    # lookup ticket and clear it
    ticketId = res.match[1]
    robot.brain.remove "#{NAMESPACE}#{ticketId}"
    res.send "Removed estimation for #{ticketId}"

  robot.hear /estimate total (.*) for (.*)/i, id: 'estimate.total', (res) ->
    votersCountTrimmed = res.match[1].trim()
    ticketId = res.match[2]

    votersCount = Number(votersCountTrimmed)
    isInteger = votersCount % 1 == 0

    if votersCountTrimmed == "" || !isInteger || votersCount < 2
      res.send "Enter an integer greater than 1 for the total number of voters"
      return

    ticket = robot.brain.get("#{NAMESPACE}#{ticketId}") || {}
    ticketVoteCount = Object.keys(ticket).length
    if ticketVoteCount >= votersCount
      res.send "Already reached max #{votersCount} votes for #{ticketId}"
    else
      robot.brain.set("#{NAMESPACE}#{ticketId}#{TOTAL_VOTERS}", votersCount)
      res.send "Waiting for #{votersCount} votes to print total for #{ticketId}"

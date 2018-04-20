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

sanitizedUsername = (member) ->
  return member unless member?
  member = member.trim().toLowerCase()
  if member[0] == "@" then member.slice(1) else member

teamNamespace = (username) ->
  "#{NAMESPACE}username-#{username}"

estimateFor = ({ robot, res, ticketId }) ->
  ticket = robot.brain.get "#{NAMESPACE}#{ticketId}"
  if !ticket
    res.send noEstimationMessage(ticketId)
    return

  user = res.message.user.name.toLowerCase()
  team = robot.brain.get teamNamespace(user)

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
  projectId = team?.projectId
  if HUBOT_PIVOTAL_TOKEN? && projectId?
    updatePivotalTicket({ robot, res, projectId, ticketId, points })

updatePivotalTicket = ({ robot, res, projectId, ticketId, points }) ->
  data = JSON.stringify { estimate: points }
  url = "#{TRACKER_BASE_URL}/projects/#{projectId}/stories/#{ticketId}"
  robot.http(url)
    .header("Content-Type", "application/json")
    .header("X-TrackerToken", HUBOT_PIVOTAL_TOKEN)
    .put(data) (err) ->
      if err
        robot.logger.debug err
      else
        res.send "Updated ticket ##{ticketId} with #{points} point(s)"

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

    ticketVoteCount = Object.keys(ticket).length

    # check if a team is set
    team = robot.brain.get teamNamespace(user)
    if ticketVoteCount >= team?.members.length
      return estimateFor({ robot, res, ticketId })

    # check for max voters count
    totalVotersCount = robot.brain.get("#{NAMESPACE}#{ticketId}#{TOTAL_VOTERS}")
    return unless totalVotersCount

    # if we've reached max voters, print the estimate
    if ticketVoteCount >= totalVotersCount
      estimateFor({ robot, res, ticketId })

  robot.respond /estimate team(.*)/i, id: 'estimate.team', (res) ->
    options = res.match[1]?.split(',')?.filter(String)
    channel = options[0]?.trim()

    if !options?.length || !channel?.length
      res.send "Please run the command: estimate team <channel>, <pivotal_project_id>, [<team_members>]"
      return

    projectId = options[1]?.trim()

    if !projectId?.length
      res.send "Please add your team's Pivotal Tracker project id"
      return

    members = options.slice(2)
      .join(',')
      .match(/\[(.*)\]/i)?[1]?.split(',')
      .filter(String)
      .map(sanitizedUsername)

    if !members
      res.send "Please add team members in the form of [@name, @anothername]"
      return

    if members?.length == 0
      res.send "Please add at least one team member"
      return

    members.forEach (member) ->
      robot.brain.set teamNamespace(member), {
        channel, projectId, members
      }

    res.send "Team created for channel: #{channel}" +
      ", project id: #{projectId}, and member(s): #{members.join(', ')}"

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

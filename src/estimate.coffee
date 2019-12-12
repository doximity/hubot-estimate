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
# Author:
#   kleinjm

http = require "http"

ESTIMATE_FIBONACCI_SEQUENCE = process.env.ESTIMATE_FIBONACCI_SEQUENCE == 'true'
HUBOT_PIVOTAL_TOKEN = process.env.HUBOT_PIVOTAL_TOKEN
NAMESPACE = "hubot-estimate-"
TOTAL_VOTERS = "-max-voters"
TRACKER_BASE_URL = "https://www.pivotaltracker.com/services/v5"

FIBONACCI_SEQUENCE = [0, 1, 2, 3, 5, 8, 13, 21, 34, 55]

closestNumberInFibonacci = (ceilingResult) ->
  lastNumberInSequence = 0
  for number in FIBONACCI_SEQUENCE
    return number if ceilingResult < number && ceilingResult > lastNumberInSequence
    lastNumberInSequence = number

median = (ticket) ->
  values = (parseInt(value) for own prop, value of ticket)
  values.sort  (a, b) -> return a - b
  half = Math.floor values.length/2
  ceilingResult =
    if values.length % 2
      Math.ceil values[half]
    else
      Math.ceil((values[half-1] + values[half]) / 2.0)

  return ceilingResult unless ESTIMATE_FIBONACCI_SEQUENCE
  return ceilingResult if ceilingResult in FIBONACCI_SEQUENCE
  closestNumberInFibonacci(ceilingResult)

listVoters = (ticket, withVote = false) ->
  voters = ""
  for voter, vote of ticket
    if voters != ""
      voters = voters + ", "
    voters = voters + (if withVote then "#{voter}: #{vote}" else voter)
  voters

noEstimationMessage = (ticketId) ->
  "There is no estimation for story #{ticketId}"

sanitizedName = (name, charToRemove) ->
  return name unless name?
  name = name.trim().toLowerCase()
  if name[0] == charToRemove then name.slice(1) else name

teamNamespace = (username) ->
  "#{NAMESPACE}username-#{username}"

estimateFor = ({ robot, res, ticketId, room }) ->
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
  else
    msg = "Median vote of #{median(ticket)} by #{listVoters(ticket, true)}"

  # post to pivotal tracker
  projectId = team?.projectId
  if HUBOT_PIVOTAL_TOKEN? && projectId?
    messagePrefix = msg
    updatePivotalTicket({
      robot, res, projectId, ticketId, points: median(ticket), room, messagePrefix
    })
  else
    if room then robot.messageRoom(room, msg) else res.send msg


updatePivotalTicket = ({ robot, res, projectId, ticketId, points, room, messagePrefix }) ->
  data = JSON.stringify { estimate: points }
  url = "#{TRACKER_BASE_URL}/projects/#{projectId}/stories/#{ticketId}"
  storyUrl = "https://www.pivotaltracker.com/story/show/#{ticketId}"
  robot.http(url)
    .header("Content-Type", "application/json")
    .header("X-TrackerToken", HUBOT_PIVOTAL_TOKEN)
    .put(data) (err, _, body) ->
      if err
        robot.logger.debug err
      else
        response = JSON.parse body
        robot.logger.debug response
        generalProblem = response.general_problem
        if generalProblem?
          msg = "Error updating ticket: #{generalProblem}\n#{storyUrl}"
        else
          ticketName = response.name
          msg = "Updated \"#{ticketName}\" with #{points} point(s)\n#{storyUrl}"

        msg = "#{messagePrefix}\n\n#{msg}" if messagePrefix?.length
        if room then robot.messageRoom(room, msg) else res.send msg

module.exports = (robot) ->
  robot.respond /estimate (.*) as (.*)/i, id: 'estimate.estimate', (res) ->
    # tell the user what they voted for and what the vote is
    ticketId = res.match[1].trim().replace(/^#/, '')
    pointsTrimmed = res.match[2].trim()
    points = Number(pointsTrimmed)

    isInteger = points % 1 == 0

    if pointsTrimmed == "" || !isInteger || points < 0
      res.send "Please enter a positive integer for your vote"
      return

    if ESTIMATE_FIBONACCI_SEQUENCE && points not in FIBONACCI_SEQUENCE
      res.send "#{pointsTrimmed} is an invalid estimate. Please use the Fibonacci sequence"
      return

    res.send "You've estimated story #{ticketId} as #{points} points"

    # set the key value pair for that ticket for this user
    ticket = robot.brain.get("#{NAMESPACE}#{ticketId}") || {}
    user = res.message.user.name.toLowerCase()
    ticket[user] = points
    robot.brain.set "#{NAMESPACE}#{ticketId}", ticket

    ticketVoteCount = Object.keys(ticket).length

    # check if a team is set
    team = robot.brain.get teamNamespace(user)
    if ticketVoteCount >= team?.members.length
      return estimateFor({ robot, res, ticketId, room: team?.channel })

    # check for max voters count
    { room, votersCount } =
      robot.brain.get("#{NAMESPACE}#{ticketId}#{TOTAL_VOTERS}") || {}
    return unless votersCount && room

    # if we've reached max voters, print the estimate
    if ticketVoteCount >= votersCount
      estimateFor({ robot, res, ticketId, room })

  robot.respond /estimate team(.*)/i, id: 'estimate.team', (res) ->
    options = res.match[1]?.split(',')?.filter(String)
    channel = sanitizedName(options[0], "#")

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
      .map((name) -> sanitizedName(name, '@'))

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
    ticketId = res.match[1].trim().replace(/^#/, '')
    estimateFor({ robot, res, ticketId })

  robot.hear /estimate voters for (.*)/i, id: 'estimate.voters-for', (res) ->
    # check if the ticket exists and return if not
    ticketId = res.match[1].trim().replace(/^#/, '')
    ticket = robot.brain.get "#{NAMESPACE}#{ticketId}"
    if !ticket
      res.send noEstimationMessage(ticketId)
      return

    res.send "People who voted for #{ticketId}: #{listVoters(ticket)}"

  robot.hear /estimate remove (.*)/i, id: 'estimate.remove', (res) ->
    # lookup ticket and clear it
    ticketId = res.match[1].trim().replace(/^#/, '')
    robot.brain.remove "#{NAMESPACE}#{ticketId}"
    res.send "Removed estimation for #{ticketId}"

  robot.hear /estimate max (.*) for (.*)/i, id: 'estimate.max', (res) ->
    votersCountTrimmed = res.match[1].trim()
    ticketId = res.match[2].trim().replace(/^#/, '')
    room = res.message.room

    votersCount = Number(votersCountTrimmed)
    isInteger = votersCount % 1 == 0

    if votersCountTrimmed == "" || !isInteger || votersCount < 2
      res.send "Enter an integer greater than 1 for the max number of voters"
      return

    ticket = robot.brain.get("#{NAMESPACE}#{ticketId}") || {}
    ticketVoteCount = Object.keys(ticket).length
    if ticketVoteCount >= votersCount
      res.send "Already reached max #{votersCount} votes for #{ticketId}"
    else
      robot.brain.set(
        "#{NAMESPACE}#{ticketId}#{TOTAL_VOTERS}", { room, votersCount }
      )
      res.send "Waiting for #{votersCount} votes to print max for #{ticketId}"

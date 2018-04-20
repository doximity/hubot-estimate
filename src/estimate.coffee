# Description:
#   Sets up and allows estimation voting on a given topic. Used for sprint
#   estimation meetings and async voting.
#
# Commands:
#   hubot estimate <ticket_id> as <points> - saves estimate
#   hubot estimate for <ticket_id> - lists the estimate with user names
#   hubot estimate voters for <ticket_id> - lists the users names voted
#   hubot estimate remove <ticket_id> - removes votes for given ticket_id
#
# Notes:
#  Estimations follow the naming convention `#{NAMESPACE}123` in redis
#
# Author:
#   kleinjm

NAMESPACE = "doximity-estimate-"

median = (ticket) ->
  values = (parseInt(value) for own prop, value of ticket)
  values.sort  (a, b) -> return a - b
  half = Math.floor values.length/2
  if values.length % 2
    values[half]
  else
    (values[half-1] + values[half]) / 2.0

listVoters = (ticket, withVote = false) ->
  voters = ""
  for voter, vote of ticket
    if voters != ""
      voters = voters + ", "
    voters = voters + (if withVote then "#{voter}: #{vote}" else voter)
  voters

noEstimationMessage = (ticketId) ->
  "There is no estimation for story #{ticketId}"

module.exports = (robot) ->
  robot.respond /estimate (.*) as (.*)/i, (res) ->
    # tell the user what they voted for and what the vote is
    ticketId = res.match[1]
    pointsTrimmed = res.match[2].trim()
    points = Number(pointsTrimmed)

    isInteger = points % 1 == 0

    if pointsTrimmed != "" && points >= 0 && isInteger
      res.send "You've estimated story #{ticketId} as #{points} points"
    else
      res.send "Please enter a positive integer for your vote"

    # set the key value pair for that ticket for this user
    existingTicket = robot.brain.get("#{NAMESPACE}#{ticketId}") || {}
    user = res.message.user.name.toLowerCase()
    existingTicket[user] = points
    robot.brain.set "#{NAMESPACE}#{ticketId}", existingTicket

  robot.hear /estimate for (.*)/i, (res) ->
    # check if the ticket exists and return if not
    ticketId = res.match[1]
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

  robot.hear /estimate voters for (.*)/i, (res) ->
    # check if the ticket exists and return if not
    ticketId = res.match[1]
    ticket = robot.brain.get "#{NAMESPACE}#{ticketId}"
    if !ticket
      res.send noEstimationMessage(ticketId)
      return

    res.send "People who voted for #{ticketId}: #{listVoters(ticket)}"

  robot.hear /estimate remove (.*)/i, (res) ->
    # lookup ticket and clear it
    ticketId = res.match[1]
    robot.brain.remove "#{NAMESPACE}#{ticketId}"
    res.send "Removed estimation for #{ticketId}"

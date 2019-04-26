class Ticket
  constructor: (@ticketId, @brain) ->
    @ticketData = @brain.get(@ticketId)

  save: ->
    @brain.set(@ticketId, @ticketData)

  delete: ->
    @brain.unset(@ticketId)

  addVote: (user, vote) ->
    @ticketData[user] = vote
    if @estimationFinished()
      @produceEstimation
    @save()


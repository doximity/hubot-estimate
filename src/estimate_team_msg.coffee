charRemover = require('./char_remover')

module.exports = class EstimateTeamMsg
  # estimate team(*.)/i
  # estimate team #channel, pivotal_project_id, [@member1, @member2, @member3]
  constructor: (@plainMessage) ->
    @splitMessage = @plainMessage?.split(',')?.filter(String)

  valid: () ->
    @channel()? && @projectId()? && (@members()?.length > 0)

  channel: () ->
    charRemover(@splitMessage[0], "#") if @splitMessage?

  projectId: () ->
    @splitMessage[1]?.trim() if @splitMessage?

  members: () ->
    return undefined unless @splitMessage?[2]?
    plainMsgWithoutChannelAndProject = @splitMessage?.slice(2).join(',')
    plainMsgWithoutChannelAndProject
      .match(/\[(.*)\]/i)?[1]?.split(',')
      .filter(String)
      .map((name) -> charRemover(name, '@'))

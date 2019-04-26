module.exports = class TeamManager
  constructor: (options) ->
    @brain = options.brain

  createTeam: (options) ->
    channel = options.channel
    projectId = options.projectId
    members = options.members

    members.forEach (member) =>
      key = "username-#{member}"
      @brain.set key,
        channel: channel,
        projectId: projectId,
        members: members

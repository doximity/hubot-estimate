chai = require('chai')
sinon = require('sinon')
expect = chai.expect
assert = chai.assert

TeamManager = require('../src/team_manager.coffee')

describe 'team creation', ->
  it 'stores on brain', ->
    brain = { set: sinon.fake(), get: sinon.fake() }
    manager = new TeamManager(brain: brain)
    manager.createTeam
      channel: "my-channel"
      projectId: 123
      members: ["member1", "member2"]
    assert(brain.set.calledWith("username-member1"))
    assert(brain.set.calledWith("username-member2"))


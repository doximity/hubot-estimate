expect = require('chai').expect
EstimateTeamMsg = require('../src/estimate_team_msg.coffee')

describe 'estimate team msg', ->
  describe 'happy path', ->
    beforeEach ->
      @msg = new EstimateTeamMsg("#estimators, 12345, [@one, @two, @three]")

    it "gets the channel name", ->
      expect(@msg.channel()).to.eq "estimators"

    it "gets the project id", ->
      expect(@msg.projectId()).to.eq "12345"

    it "gets the member list", ->
      expect(@msg.members()).to.eql ["one", "two", "three"]

  describe 'with no message', ->
    beforeEach ->
      @msg = new EstimateTeamMsg(null)

    it "returns undefined for channel", ->
      expect(@msg.channel()).to.not.throw
      expect(@msg.channel()).to.be.undefined

    it "returns undefined for projectId", ->
      expect(@msg.projectId()).to.not.throw
      expect(@msg.projectId()).to.be.undefined

    it "returns undefined for members", ->
      expect(@msg.members()).to.not.throw
      expect(@msg.members()).to.be.undefined

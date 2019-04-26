Helper = require 'hubot-test-helper'
expect = require('chai').expect
helper = new Helper('../src/estimate2.coffee')

describe 'estimate', ->
  createRoom = (options = {}) ->
    room = helper.createRoom(options)
    room.lastMessage = () -> room.messages[room.messages.length - 1]
    room

  beforeEach ->
    @room = createRoom(name: 'my-room', httpd: false)

  afterEach ->
    @room.destroy()

  describe 'hubot estimate team <channel>, <pivotal_project_id>, [<team_members>]', ->
    it 'outputs verification for all args', ->
      @room.user.say('malkomalko', 'hubot estimate team #channel1, 123, [@Sally, @jim]').then =>
        expect(@room.messages).to.eql [
          ['malkomalko', 'hubot estimate team #channel1, 123, [@Sally, @jim]'],
          ['hubot', 'Team created for channel: #channel1, project id: 123, and member(s): sally, jim']
        ]

    it 'requires options to be set', ->
      @room.user.say('malkomalko', 'hubot estimate team').then =>
        expect(@room.lastMessage()).to.eql(
          ['hubot', "I will do no such thing unless you run the correct command: estimate team <channel>, <pivotal_project_id>, [@member, @other_member]"]
        )

    it 'requires a team slack channel to be set', ->
      @room.user.say('malkomalko', 'hubot estimate team ,').then =>
        expect(@room.lastMessage()).to.eql(
          ['hubot', "I will do no such thing unless you run the correct command: estimate team <channel>, <pivotal_project_id>, [@member, @other_member]"]
        )

    it 'requires a pivotal project id to be set', ->
      @room.user.say('malkomalko', 'hubot estimate team #channel1,').then =>
        expect(@room.lastMessage()).to.eql(
          ['hubot', "I will do no such thing unless you run the correct command: estimate team <channel>, <pivotal_project_id>, [@member, @other_member]"]
        )

    it 'requires team members to be set', ->
      @room.user.say('malkomalko', 'hubot estimate team #channel1, 123,').then =>
        expect(@room.lastMessage()).to.eql(
          ['hubot', "I will do no such thing unless you run the correct command: estimate team <channel>, <pivotal_project_id>, [@member, @other_member]"]
        )

    it 'requires at least one team member', ->
      @room.user.say('malkomalko', 'hubot estimate team #channel1, 123, []').then =>
        expect(@room.lastMessage()).to.eql(
          ['hubot', "I will do no such thing unless you run the correct command: estimate team <channel>, <pivotal_project_id>, [@member, @other_member]"]
        )

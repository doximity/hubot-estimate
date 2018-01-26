Helper = require 'hubot-test-helper'
expect = require('chai').expect
helper = new Helper('../src/estimate.coffee')

describe 'estimate', ->
  beforeEach ->
    @room = helper.createRoom()
    @room.lastMessage = () => @room.messages[@room.messages.length - 1]

  afterEach ->
    @room.destroy()

  describe 'estimate <ticket_id> as <points>', ->
    it 'outputs verification', ->
      @room.user.say('kleinjm', 'estimate 1 as 3').then =>
        expect(@room.messages).to.eql [
          ['kleinjm', 'estimate 1 as 3']
          ['hubot', "You've estimated story 1 as 3 points"]
        ]

  describe 'estimate for <ticket_id>', ->
    it 'returns a no estimation message if no estimates', ->
      @room.user.say('kleinjm', 'estimate for 1').then =>
        expect(@room.lastMessage()).to.eql(
          ['hubot', 'There is no estimation for story 1']
        )

    context 'non-unanimous votes', ->
      it 'returns a list of users and median for odd number of users', ->
        @room.user.say('kleinjm', 'estimate 1 as 3')
        @room.user.say('krish', 'estimate 1 as 5')
        @room.user.say('rstawarz', 'estimate 1 as 5')
        @room.user.say('kleinjm', 'estimate for 1').then =>
          expect(@room.lastMessage()).to.eql(
            ['hubot', 'Median vote of 5 by kleinjm: 3, krish: 5, rstawarz: 5']
          )

      it 'returns a list of users and median for even number of users', ->
        @room.user.say('kleinjm', 'estimate 1 as 3')
        @room.user.say('rstawarz', 'estimate 1 as 5')
        @room.user.say('kleinjm', 'estimate for 1').then =>
          expect(@room.lastMessage()).to.eql(
            ['hubot', 'Median vote of 4 by kleinjm: 3, rstawarz: 5']
          )

    it 'returns a message and list of users if unanimous', ->
      @room.user.say('kleinjm', 'estimate 1 as 3')
      @room.user.say('rstawarz', 'estimate 1 as 3')
      @room.user.say('kleinjm', 'estimate for 1').then =>
        expect(@room.lastMessage()).to.eql(
          ['hubot', 'Unanimous estimation of 3 points by kleinjm, rstawarz']
        )

  describe 'estimate voters for <ticket_id>', ->
    it 'returns a no estimation message if no estimates', ->
      @room.user.say('kleinjm', 'estimate voters for 1').then =>
        expect(@room.lastMessage()).to.eql(
          ['hubot', 'There is no estimation for story 1']
        )

    it 'returns a list of users that have voted', ->
      @room.user.say('kleinjm', 'estimate 1 as 3')
      @room.user.say('rstawarz', 'estimate 1 as 5')
      @room.user.say('kleinjm', 'estimate voters for 1').then =>
        expect(@room.lastMessage()).to.eql(
          ['hubot', 'People who voted for 1: kleinjm, rstawarz']
        )

  describe 'estimate remove <ticket_id>', ->
    it 'confirms removal', ->
      @room.user.say('kleinjm', 'estimate 1 as 3')
      @room.user.say('kleinjm', 'estimate remove 1').then(() =>
        expect(@room.lastMessage()).to.eql(
          ['hubot', 'Removed estimation for 1']
        )
      ).then =>
        @room.user.say('kleinjm', 'estimate for 1').then =>
          expect(@room.lastMessage()).to.eql(
            ['hubot', 'There is no estimation for story 1']
          )

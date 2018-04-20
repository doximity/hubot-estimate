Helper = require 'hubot-test-helper'
expect = require('chai').expect
helper = new Helper('../src/estimate.coffee')

describe 'estimate', ->
  beforeEach ->
    @room = helper.createRoom()
    @room.lastMessage = () => @room.messages[@room.messages.length - 1]

  afterEach ->
    @room.destroy()

  describe 'hubot estimate <ticket_id> as <points>', ->
    it 'outputs verification for positive integers', ->
      @room.user.say('kleinjm', 'hubot estimate 1 as 3').then =>
        expect(@room.messages).to.eql [
          ['kleinjm', 'hubot estimate 1 as 3']
          ['hubot', "You've estimated story 1 as 3 points"]
        ]

    it 'outputs verification for 0', ->
      @room.user.say('kleinjm', 'hubot estimate 1 as 0').then =>
        expect(@room.messages).to.eql [
          ['kleinjm', 'hubot estimate 1 as 0']
          ['hubot', "You've estimated story 1 as 0 points"]
        ]

    it 'handles extra whitespace around story name', ->
      @room.user.say('kleinjm', 'hubot estimate     1     as 3').then =>
        expect(@room.messages).to.eql [
          ['kleinjm', 'hubot estimate     1     as 3']
          ['hubot', "You've estimated story 1 as 3 points"]
        ]

    it 'only responds to being directly addressed', ->
      @room.user.say('kleinjm', 'estimate 1 as 1').then =>
        expect(@room.messages).to.eql [
          ['kleinjm', 'estimate 1 as 1']
        ]

    it 'does not allow string input', ->
      @room.user.say('kleinjm', 'hubot estimate 1 as not an int').then =>
        expect(@room.messages).to.eql [
          ['kleinjm', 'hubot estimate 1 as not an int']
          ['hubot', "Please enter a positive integer for your vote"]
        ]

    it 'does not allow empty input', ->
      @room.user.say('kleinjm', 'hubot estimate 1 as ').then =>
        expect(@room.messages).to.eql [
          ['kleinjm', 'hubot estimate 1 as ']
          ['hubot', "Please enter a positive integer for your vote"]
        ]

    it 'does not allow negative input', ->
      @room.user.say('kleinjm', 'hubot estimate 1 as -3').then =>
        expect(@room.messages).to.eql [
          ['kleinjm', 'hubot estimate 1 as -3']
          ['hubot', "Please enter a positive integer for your vote"]
        ]

    it 'does not allow decimal input', ->
      @room.user.say('kleinjm', 'hubot estimate 1 as 3.4').then =>
        expect(@room.messages).to.eql [
          ['kleinjm', 'hubot estimate 1 as 3.4']
          ['hubot', "Please enter a positive integer for your vote"]
        ]

  describe 'estimate for <ticket_id>', ->
    it 'returns a no estimation message if no estimates', ->
      @room.user.say('kleinjm', 'estimate for 1').then =>
        expect(@room.lastMessage()).to.eql(
          ['hubot', 'There is no estimation for story 1']
        )

    context 'non-unanimous votes', ->
      it 'returns a list of users and median for odd number of users', ->
        @room.user.say('kleinjm', 'hubot estimate 1 as 3')
        @room.user.say('coworker2', 'hubot estimate 1 as 5')
        @room.user.say('coworker1', 'hubot estimate 1 as 5')
        @room.user.say('kleinjm', 'estimate for 1').then =>
          expect(@room.lastMessage()).to.eql(
            ['hubot', 'Median vote of 5 by kleinjm: 3, coworker2: 5, coworker1: 5']
          )

      it 'returns a list of users and median for even number of users', ->
        @room.user.say('kleinjm', 'hubot estimate 1 as 3')
        @room.user.say('coworker1', 'hubot estimate 1 as 5')
        @room.user.say('kleinjm', 'estimate for 1').then =>
          expect(@room.lastMessage()).to.eql(
            ['hubot', 'Median vote of 4 by kleinjm: 3, coworker1: 5']
          )

      it 'rounds a median vote up', ->
        @room.user.say('kleinjm', 'hubot estimate 1 as 3')
        @room.user.say('coworker1', 'hubot estimate 1 as 4')
        @room.user.say('kleinjm', 'estimate for 1').then =>
          expect(@room.lastMessage()).to.eql(
            ['hubot', 'Median vote of 4 by kleinjm: 3, coworker1: 4']
          )

    it 'returns a message and list of users if unanimous', ->
      @room.user.say('kleinjm', 'hubot estimate 1 as 3')
      @room.user.say('coworker1', 'hubot estimate 1 as 3')
      @room.user.say('kleinjm', 'estimate for 1').then =>
        expect(@room.lastMessage()).to.eql(
          ['hubot', 'Unanimous estimation of 3 points by kleinjm, coworker1']
        )

  describe 'estimate voters for <ticket_id>', ->
    it 'returns a no estimation message if no estimates', ->
      @room.user.say('kleinjm', 'estimate voters for 1').then =>
        expect(@room.lastMessage()).to.eql(
          ['hubot', 'There is no estimation for story 1']
        )

    it 'returns a list of users that have voted', ->
      @room.user.say('kleinjm', 'hubot estimate 1 as 3')
      @room.user.say('coworker1', 'hubot estimate 1 as 5')
      @room.user.say('kleinjm', 'estimate voters for 1').then =>
        expect(@room.lastMessage()).to.eql(
          ['hubot', 'People who voted for 1: kleinjm, coworker1']
        )

  describe 'estimate remove <ticket_id>', ->
    it 'confirms removal', ->
      @room.user.say('kleinjm', 'hubot estimate 1 as 3')
      @room.user.say('kleinjm', 'estimate remove 1').then(() =>
        expect(@room.lastMessage()).to.eql(
          ['hubot', 'Removed estimation for 1']
        )
      ).then =>
        @room.user.say('kleinjm', 'estimate for 1').then =>
          expect(@room.lastMessage()).to.eql(
            ['hubot', 'There is no estimation for story 1']
          )

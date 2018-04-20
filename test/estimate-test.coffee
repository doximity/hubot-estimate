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
        expect(@room.lastMessage()).to.eql(
          ['hubot', "You've estimated story 1 as 0 points"]
        )

    it 'handles extra whitespace around story name', ->
      @room.user.say('kleinjm', 'hubot estimate     1     as 3').then =>
        expect(@room.lastMessage()).to.eql(
          ['hubot', "You've estimated story 1 as 3 points"]
        )

    it 'only responds to being directly addressed', ->
      @room.user.say('kleinjm', 'estimate 1 as 1').then =>
        expect(@room.messages).to.eql [
          ['kleinjm', 'estimate 1 as 1']
        ]

    it 'does not respond to empty input', ->
      @room.user.say('kleinjm', 'hubot estimate 1 as ').then =>
        expect(@room.lastMessage()).to.eql(
          ['hubot', "Please enter a positive integer for your vote"]
        )

    it 'does not allow string input', ->
      @room.user.say('kleinjm', 'hubot estimate 1 as not an int').then =>
        expect(@room.lastMessage()).to.eql(
          ['hubot', "Please enter a positive integer for your vote"]
        )

    it 'does not allow negative input', ->
      @room.user.say('kleinjm', 'hubot estimate 1 as -3').then =>
        expect(@room.lastMessage()).to.eql(
          ['hubot', "Please enter a positive integer for your vote"]
        )

    it 'does not allow decimal input', ->
      @room.user.say('kleinjm', 'hubot estimate 1 as 3.4').then =>
        expect(@room.lastMessage()).to.eql(
          ['hubot', "Please enter a positive integer for your vote"]
        )

  describe 'hubot estimate team <channel>, <pivotal_project_id>, [<team_members>]', ->
    it 'outputs verification for all args', ->
      @room.user.say('malkomalko', 'hubot estimate team #channel1, 123, [@sally, @jim]').then =>
        expect(@room.messages).to.eql [
          ['malkomalko', 'hubot estimate team #channel1, 123, [@sally, @jim]'],
          ['hubot', '#channel1, 123, 2']
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
            [
              'hubot',
              'Median vote of 5 by kleinjm: 3, coworker2: 5, coworker1: 5'
            ]
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

  describe 'estimate total <voters_count> for <ticket_id>', ->
    it 'prints the vote when the voters_count is reached', ->
      @room.user.say('kleinjm', 'estimate total 2 for 123').then(() =>
        expect(@room.lastMessage()).to.eql(
          ['hubot', 'Waiting for 2 votes to print total for 123']
        )
        @room.user.say('kleinjm', 'hubot estimate 123 as 2')
        @room.user.say('coworker1', 'hubot estimate 123 as 2').then(() =>
          expect(@room.lastMessage()).to.eql(
            ['hubot', 'Unanimous estimation of 2 points by kleinjm, coworker1']
          )
        )
      )

    it 'warns if a total has already been reached', ->
      @room.user.say('kleinjm', 'hubot estimate 123 as 2')
      @room.user.say('coworker1', 'hubot estimate 123 as 2')
      @room.user.say('kleinjm', 'estimate total 2 for 123').then(() =>
        expect(@room.lastMessage()).to.eql(
          ['hubot', 'Already reached max 2 votes for 123']
        )
      )

    it 'handles extra whitespace around voters_count', ->
      @room.user.say('kleinjm', 'estimate total     2     for 123').then =>
        expect(@room.lastMessage()).to.eql(
          ['hubot', 'Waiting for 2 votes to print total for 123']
        )

    it 'does not respond to empty input', ->
      @room.user.say('kleinjm', 'estimate total for 123').then =>
        expect(@room.lastMessage()).to.eql(
          ['kleinjm', 'estimate total for 123']
        )

    it 'does not allow string input', ->
      @room.user.say('kleinjm', 'estimate total not an int for 123').then =>
        expect(@room.lastMessage()).to.eql(
          [
            'hubot',
            "Enter an integer greater than 1 for the total number of voters"
          ]
        )

    it 'does not allow negative input', ->
      @room.user.say('kleinjm', 'estimate total -1 for 123').then =>
        expect(@room.lastMessage()).to.eql(
          [
            'hubot',
            "Enter an integer greater than 1 for the total number of voters"
          ]
        )

    it 'does not allow 0 input', ->
      @room.user.say('kleinjm', 'estimate total 0 for 123').then =>
        expect(@room.lastMessage()).to.eql(
          [
            'hubot',
            "Enter an integer greater than 1 for the total number of voters"
          ]
        )

    # there is no need to ever have 1 voter
    it 'does not allow 1 input', ->
      @room.user.say('kleinjm', 'estimate total 0 for 123').then =>
        expect(@room.lastMessage()).to.eql(
          [
            'hubot',
            "Enter an integer greater than 1 for the total number of voters"
          ]
        )

    it 'does not allow decimal input', ->
      @room.user.say('kleinjm', 'estimate total 3.4 for 123').then =>
        expect(@room.lastMessage()).to.eql(
          [
            'hubot',
            "Enter an integer greater than 1 for the total number of voters"
          ]
        )

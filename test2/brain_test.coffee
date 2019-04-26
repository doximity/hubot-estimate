Helper = require 'hubot-test-helper'
expect = require('chai').expect
Brain = require('../src/brain.coffee')
botHelper = new Helper('../src/estimate2.coffee')

describe 'estimate brain interface', ->
  createRoom = (options = {}) ->
    room = botHelper.createRoom(options)
    room.lastMessage = () -> room.messages[room.messages.length - 1]
    room

  beforeEach ->
    @room = createRoom(name: 'my-room', httpd: false)
    @brain = new Brain(@room.robot)

  afterEach ->
    @room.destroy()

  describe 'automatic prefixing', ->
    it 'when seting and geting', ->
      @brain.set("foo", "bar")

      expect(@brain.get("foo")).to.eql("bar")
      expect(@brain.robot.brain.get("foo")).to.be.a("null")
      expect(@brain.robot.brain.get("hubot-estimate-foo")).to.eql("bar")


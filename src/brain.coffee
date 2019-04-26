NAMESPACE = "hubot-estimate-"
TOTAL_VOTERS = "-max-voters"

module.exports = class Brain
  constructor: (@robot) ->

  get: (key) ->
    @robot.brain.get("#{NAMESPACE}#{key}") || {}

  set: (key, value) ->
    @robot.brain.set("#{NAMESPACE}#{key}", value)

  unset: (key) ->
    @robot.brain.remove("#{NAMESPACE}#{key}")

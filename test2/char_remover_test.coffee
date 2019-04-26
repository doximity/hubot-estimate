expect = require("chai").expect
charRemover = require("../src/char_remover")

describe "char remover", ->
  it "removes the first char if present", ->
    expect(charRemover("#engineering", "#")).to.eql "engineering"
    expect(charRemover("@john", "@")).to.eql "john"

  it "doesn't remove the first char if not present", ->
    expect(charRemover("engineering", "#")).to.eql "engineering"
    expect(charRemover("john", "@")).to.eql "john"

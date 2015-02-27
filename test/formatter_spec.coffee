define [
  'src/formatter'
], (
  Formatter
) ->

  describe "Formatter", ->

    describe "#sentenceCase", ->
      it 'replaces underscores with spaces', ->
        new_string = new Formatter "Hi_there"
        expect(new_string.sentenceCase()).toBe("Hi there")

      it 'capitalizes the first letter', ->
        new_string = new Formatter "hi there"
        expect(new_string.sentenceCase()).toBe("Hi there")

    describe "#capitalize", ->
      it 'capitalizes the first letter', ->
        new_string = new Formatter "test"
        expect(new_string.capitalize()).toBe("Test")

define [
  'src/error_handler'
  'primedia_events'
], (
  ErrorHandler
  events
) ->

  describe "#generateErrors", ->
    beforeEach ->
      loadFixtures("clear_errors.html")

    describe "when there are errors", ->
      it 'adds the list items to the DOM', ->
        error = {"first_name": "can't be blank"}
        new ErrorHandler(error, $('.errors'), 'handleErrors').generateErrors()
        expect($('.errors ul')).toHaveHtml("<li>First name can't be blank</li>")

    describe "when there are NO errors", ->
      it 'adds the list item with default message', ->
        new ErrorHandler(undefined, $('.errors'), 'handleErrors').generateErrors()
        expect($('.errors ul')).toHaveHtml("An error has occurred.")

  describe "#clearErrors", ->
    beforeEach ->
      loadFixtures("clear_errors.html")
      @$div = $('.registration_form')

    it "removes error class from the div", ->
      new ErrorHandler().clearErrors(@$div)
      expect(@$div.find('form p')).not.toHaveClass('errors')

    it "empties the div of errors", ->
      new ErrorHandler().clearErrors(@$div)
      expect(@$div.find('.errors')).toBeEmpty()

    it "triggers event/loginErrorsCleared", ->
      spy = spyOn(events, 'trigger')
      new ErrorHandler().clearErrors(@$div)
      expect(spy).toHaveBeenCalledWith('event/loginErrorsCleared')

  describe '#formatError', ->
    describe 'base', ->
      it 'returns the value', ->
        message = new ErrorHandler().formatError 'base', 'test'
        expect(message).toBe('test')

    describe 'auth_key', ->
      it 'returns a the value when one is present', ->
        message = new ErrorHandler().formatError 'auth_key', 'test'
        expect(message).toBe('test')

      it 'returns an empty string when the value is falsy', ->
        message = new ErrorHandler().formatError 'auth_key', undefined
        expect(message).toBe('')
    describe 'email', ->
      it 'returns a message when value is present', ->
        message = new ErrorHandler().formatError 'email', 'test@example.com'
        expect(message).toBe('Email test@example.com')

      it 'returns an empty string when the value is blank', ->
        message = new ErrorHandler().formatError 'email', ''
        expect(message).toBe('')

    describe 'password', ->
      it 'returns a message when value is present', ->
        message = new ErrorHandler().formatError 'password', 'secret'
        expect(message).toBe('Password secret')

      it 'returns an empty string when the value is blank', ->
        message = new ErrorHandler().formatError 'password', ''
        expect(message).toBe('')

    describe 'passwword_confirmation', ->
      it 'returns a message when value is present', ->
        message = new ErrorHandler().formatError 'password_confirmation', 'secret'
        expect(message).toBe('Password confirmation secret')

    describe 'no match on switch statement', ->
      it 'returns the formatted key with value', ->
        message = new ErrorHandler().formatError 'fix_me:', 'i am fixed!'
        expect(message).toBe('Fix me: i am fixed!')


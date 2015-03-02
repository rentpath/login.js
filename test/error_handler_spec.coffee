define [
  'src/error_handler'
], (
  ErrorHandler
) ->
  describe '#_formatError', ->
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

      it 'returns the formatted key with value on fallthrough', ->
        message = new ErrorHandler().formatError 'fix_me:', 'i am fixed!'
        expect(message).toBe('Fix me: i am fixed!')

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

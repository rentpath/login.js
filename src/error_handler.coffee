define [
  'jquery'
  'primedia_events'
  'src/formatter'
  'jquery.cookie'
], (
  $
  events
  Formatter
) ->
  class ErrorHandler

    constructor: (@error, @$box, @eventName) ->

    generateErrors: () ->
      @clearErrors()
      messages = ''
      if error?
        $form = @$box.parent().find 'form'
        $.each @error, (key, value) =>
          $form.find("##{key}").parent('p').addClass 'error'
          formattedError = @formatError key, value
          messages += "<li>#{formattedError}</li>"
          $form.find('.error input:first').focus()
      else
        messages += "An error has occurred."
      @$box.append "<ul>#{messages}</ul>"
      events.trigger('event/' + eventName, error)


    formatError: (key, value) ->
      switch key
        when "base" then value
        when "auth_key"
          if value then value else ''
        when "password_confirmation" then "Password confirmation #{value}"
        else
          formatted_key = new Formatter(key).sentenceCase()
          if value then "#{formatted_key} #{value}" else ''

    clearErrors: ($div) ->
      $div.find('form p').removeClass('error')
      $div.find('.errors').empty()
      events.trigger('event/loginErrorsCleared')

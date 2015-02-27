define [], () ->
  class Formatter

    constructor: (@string) ->

    sentenceCase: () ->
      new_string = @string.replace('_', ' ')
      @capitalize(new_string)

    capitalize: (string="") ->
      if string == "" then string = @string
      string.charAt(0).toUpperCase() + string.slice(1)

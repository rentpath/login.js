define(['jquery', 'primedia_events', 'login/formatter', 'jquery.cookie'], function($, events, Formatter) {
  var ErrorHandler;
  return ErrorHandler = (function() {
    function ErrorHandler(error, $box, eventName) {
      this.error = error;
      this.$box = $box;
      this.eventName = eventName;
    }

    ErrorHandler.prototype.generateErrors = function() {
      var $form, formattedError, key, messages, ref, value;
      this.clearErrors(this.$box.parent());
      messages = '';
      if (this.error != null) {
        $form = this.$box.parent().find('form');
        ref = this.error;
        for (key in ref) {
          value = ref[key];
          $form.find("#" + key).parent('p').addClass('error');
          formattedError = this.formatError(key, value);
          messages += "<li>" + formattedError + "</li>";
          $form.find('.error input:first').focus();
        }
      } else {
        messages += "An error has occurred.";
      }
      this.$box.append("<ul>" + messages + "</ul>");
      return events.trigger('event/' + this.eventName, this.error);
    };

    ErrorHandler.prototype.formatError = function(key, value) {
      var formatted_key;
      switch (key) {
        case "base":
          return value;
        case "auth_key":
          if (value) {
            return value;
          } else {
            return '';
          }
          break;
        case "password_confirmation":
          return "Password confirmation " + value;
        default:
          formatted_key = new Formatter(key).sentenceCase();
          if (value) {
            return formatted_key + " " + value;
          } else {
            return '';
          }
      }
    };

    ErrorHandler.prototype.clearErrors = function($div) {
      $div.find('form p').removeClass('error');
      $div.find('.errors').empty();
      return events.trigger('event/loginErrorsCleared');
    };

    return ErrorHandler;

  })();
});

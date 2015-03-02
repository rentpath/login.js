define(['jquery', 'primedia_events', 'src/formatter', 'jquery.cookie'], function($, events, Formatter) {
  var ErrorHandler;
  return ErrorHandler = (function() {
    function ErrorHandler(error1, $box, eventName1) {
      this.error = error1;
      this.$box = $box;
      this.eventName = eventName1;
    }

    ErrorHandler.prototype.generateErrors = function() {
      var $form, messages;
      this.clearErrors();
      messages = '';
      if (typeof error !== "undefined" && error !== null) {
        $form = this.$box.parent().find('form');
        $.each(this.error, (function(_this) {
          return function(key, value) {
            var formattedError;
            $form.find("#" + key).parent('p').addClass('error');
            formattedError = _this._formatError(key, value);
            messages += "<li>" + formattedError + "</li>";
            return $form.find('.error input:first').focus();
          };
        })(this));
      } else {
        messages += "An error has occurred.";
      }
      this.$box.append("<ul>" + messages + "</ul>");
      return events.trigger('event/' + eventName, error);
    };

    ErrorHandler.prototype._formatError = function(key, value) {
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

    ErrorHandler.prototype._clearErrors = function($div) {
      $div.find('form p').removeClass('error');
      $div.find('.errors').empty();
      return events.trigger('event/loginErrorsCleared');
    };

    return ErrorHandler;

  })();
});

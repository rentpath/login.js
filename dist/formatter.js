define([], function() {
  var Formatter;
  return Formatter = (function() {
    function Formatter(string1) {
      this.string = string1;
    }

    Formatter.prototype.sentenceCase = function() {
      var new_string;
      new_string = this.string.split('_').join(' ');
      return this.capitalize(new_string);
    };

    Formatter.prototype.capitalize = function(string) {
      if (string == null) {
        string = "";
      }
      if (string === "") {
        string = this.string;
      }
      return string.charAt(0).toUpperCase() + string.slice(1);
    };

    return Formatter;

  })();
});

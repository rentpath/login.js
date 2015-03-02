var bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

define(['jquery', 'primedia_events', 'src/error_handler', 'jquery.cookie'], function($, events, ErrorHandler) {
  var Login;
  Login = (function() {
    var DEFAULT_OPTIONS;

    Login.prototype.hideIfLoggedInSelector = '.js_hidden_if_logged_in';

    Login.prototype.hideIfLoggedOutSelector = '.js_hidden_if_logged_out';

    DEFAULT_OPTIONS = {
      prefillEmailInput: true
    };

    function Login(options) {
      var key, value;
      if (options == null) {
        options = {};
      }
      this._triggerModal = bind(this._triggerModal, this);
      this._submitEmailRegistration = bind(this._submitEmailRegistration, this);
      this._enableLoginRegistration = bind(this._enableLoginRegistration, this);
      this.options = {};
      for (key in DEFAULT_OPTIONS) {
        value = DEFAULT_OPTIONS[key];
        this.options[key] = options[key] != null ? options[key] : value;
      }
      this._overrideDependencies();
      this.my = {
        zmail: $.cookie('zmail'),
        zid: $.cookie('zid'),
        session: $.cookie("sgn") === "temp" || $.cookie("sgn") === "perm",
        currentUrl: window.location.href,
        popupTypes: ["login", "register", "account", "reset", "confirm", "success"]
      };
      $(document).ready((function(_this) {
        return function() {
          $('body').bind('new_zid_obtained', function() {
            return _this.my.zid = $.cookie('zid');
          });
          _this._welcomeMessage();
          _this._toggleSessionState();
          _this._enableLoginRegistration();
          $.each(_this.my.popupTypes, function(index, type) {
            return _this._bindForms(type);
          });
          return $("a.logout").click(function(e) {
            return _this._logOut(e);
          });
        };
      })(this));
    }

    Login.prototype._prefillAccountName = function($div) {
      return $.ajax({
        type: "GET",
        datatype: 'json',
        url: zutron_host + "/zids/" + this.my.zid + "/",
        beforeSend: function(xhr) {
          xhr.overrideMimeType("text/json");
          return xhr.setRequestHeader("Accept", "application/json");
        },
        success: (function(_this) {
          return function(data) {
            $div.find('input[name="new_first_name"]').val(data.zid.user.first_name);
            return $div.find('input[name="new_last_name"]').val(data.zid.user.last_name);
          };
        })(this)
      });
    };

    Login.prototype._encodeURL = function(href) {
      var hash, path, ref;
      ref = href.split('#'), path = ref[0], hash = ref[1];
      hash = hash ? encodeURIComponent("#" + hash) : "";
      return path + hash;
    };

    Login.prototype.toggleRegistrationDiv = function($div) {
      if (!this.my.session) {
        this.wireupSocialLinks($div.show());
        return $.each(this.my.popupTypes, (function(_this) {
          return function(index, type) {
            return _this._bindForms(type);
          };
        })(this));
      }
    };

    Login.prototype.expireCookie = function(cookie) {
      var options;
      if (cookie) {
        options = {
          expires: new Date(1),
          path: "/",
          domain: "." + window.location.host
        };
        return $.cookie(cookie, "", options);
      }
    };

    Login.prototype.wireupSocialLinks = function($div) {
      var baseUrl, fbLink, googleLink, twitterLink;
      baseUrl = zutron_host + "?zid_id=" + this.my.zid + "&referrer=" + (encodeURIComponent(this.my.currentUrl)) + "&technique=";
      fbLink = $div.find("a.icon_facebook48");
      twitterLink = $div.find("a.icon_twitter48");
      googleLink = $div.find("a.icon_google_plus48");
      this._bindSocialLink(fbLink, baseUrl + "facebook", $div);
      this._bindSocialLink(twitterLink, baseUrl + "twitter", $div);
      return this._bindSocialLink(googleLink, baseUrl + "google_oauth2", $div);
    };

    Login.prototype._welcomeMessage = function() {
      var element;
      element = $('#welcome_message');
      if (element.length > 0) {
        if ($.cookie("user_type") === "new") {
          this._triggerModal(element);
        }
        return this.expireCookie("user_type");
      }
    };

    Login.prototype._enableLoginRegistration = function() {
      $('#zutron_register_form form').submit((function(_this) {
        return function(e) {
          return _this._submitEmailRegistration($(e.target));
        };
      })(this));
      $('#zutron_account_form form').submit((function(_this) {
        return function(e) {
          return _this._submitChangeUserData($(e.target));
        };
      })(this));
      $('#zutron_login_form form').submit((function(_this) {
        return function(e) {
          return _this._submitLogin($(e.target));
        };
      })(this));
      $('#zutron_reset_form form').submit((function(_this) {
        return function(e) {
          return _this._submitPasswordReset($(e.target));
        };
      })(this));
      return $('#zutron_confirm_form form').submit((function(_this) {
        return function(e) {
          return _this._submitPasswordConfirm($(e.target));
        };
      })(this));
    };

    Login.prototype._submitEmailRegistration = function($form) {
      this._setHiddenValues($form);
      return $.ajax({
        type: 'POST',
        data: $form.serialize(),
        url: zutron_host + "/auth/identity/register",
        beforeSend: function(xhr) {
          xhr.overrideMimeType("text/json");
          return xhr.setRequestHeader("Accept", "application/json");
        },
        success: (function(_this) {
          return function(data) {
            if (data['redirectUrl']) {
              _this._stayOrLeave($form);
              $("#zutron_login_form, #zutron_registration").prm_dialog_close();
              _this._setSessionType();
              _this._setEmail($form.find("#email").val());
              events.trigger('event/emailRegistrationSuccess', data);
              return _this._redirectOnSuccess(data, $form);
            } else {
              return new ErrorHandler(data, $form.parent().find(".errors"), 'emailRegistrationSuccessError').generateErrors();
            }
          };
        })(this),
        error: (function(_this) {
          return function(errors) {
            return new ErrorHandler($.parseJSON(errors.responseText), $form.parent().find(".errors"), 'emailRegistrationError').generateErrors();
          };
        })(this)
      });
    };

    Login.prototype._submitLogin = function($form) {
      this._setHiddenValues($form);
      return $.ajax({
        type: "POST",
        data: $form.serialize(),
        url: zutron_host + "/auth/identity/callback",
        beforeSend: function(xhr) {
          xhr.overrideMimeType("text/json");
          return xhr.setRequestHeader("Accept", "application/json");
        },
        success: (function(_this) {
          return function(data) {
            if (data['redirectUrl']) {
              _this._stayOrLeave($form);
              $("#zutron_login_form, #zutron_registration").prm_dialog_close();
              _this._setSessionType();
              _this._setEmail($form.find("#auth_key").val());
              events.trigger('event/loginSuccess', data);
              return _this._redirectOnSuccess(data, $form);
            } else {
              return new ErrorHandler(data, $form.parent().find(".errors"), 'loginSuccessError').generateErrors();
            }
          };
        })(this),
        error: (function(_this) {
          return function(errors) {
            return new ErrorHandler($.parseJSON(errors.responseText), $form.parent().find(".errors"), 'loginError').generateErrors();
          };
        })(this)
      });
    };

    Login.prototype._submitChangeUserData = function($form) {
      var user_data;
      user_data = {
        first_name: $('input[name="new_first_name"]').val(),
        last_name: $('input[name="new_last_name"]').val(),
        email: $('input[name="new_email"]').val(),
        email_confirmation: $('input[name="new_email_confirm"]').val()
      };
      return $.ajax({
        type: "GET",
        data: user_data,
        datatype: 'json',
        url: zutron_host + "/zids/" + this.my.zid + "/email_change.json",
        beforeSend: function(xhr) {
          xhr.overrideMimeType("text/json");
          return xhr.setRequestHeader("Accept", "application/json");
        },
        success: (function(_this) {
          return function(data) {
            if ((data != null) && data.errors) {
              return new ErrorHandler(data.errors, $form.parent().find(".errors", 'changeEmailSuccessError')).generateErrors();
            } else {
              _this._setEmail(user_data.email);
              events.trigger('event/changeEmailSuccess', data);
              $('#zutron_account_form').prm_dialog_close();
              return _this._triggerModal($("#zutron_success_form"));
            }
          };
        })(this),
        error: (function(_this) {
          return function(errors) {
            return new ErrorHandler($.parseJSON(errors.responseText), $form.parent().find(".errors", 'changeEmailError')).generateErrors();
          };
        })(this)
      });
    };

    Login.prototype._submitPasswordReset = function($form) {
      return $.ajax({
        type: 'POST',
        url: zutron_host + "/password_reset?" + ($form.serialize()),
        beforeSend: function(xhr) {
          xhr.overrideMimeType("text/json");
          return xhr.setRequestHeader("Accept", "application/json");
        },
        success: (function(_this) {
          return function(data) {
            var error;
            if (data.error) {
              error = {
                'email': data.error
              };
              return new ErrorHandler(error, $form.parent().find(".errors"), 'passwordResetSuccessError').generateErrors();
            } else {
              $form.parent().empty();
              events.trigger('event/passwordResetSuccess', data);
              return $('.reset_success').html(data.success).show();
            }
          };
        })(this),
        error: (function(_this) {
          return function(errors) {
            return new ErrorHandler($.parseJSON(errors.responseText), $form.parent().find(".errors", 'passwordResetError')).generateErrors();
          };
        })(this)
      });
    };

    Login.prototype._submitPasswordConfirm = function($form) {
      return $.ajax({
        type: 'POST',
        data: $form.serialize(),
        url: zutron_host + "/password_confirmation",
        beforeSend: function(xhr) {
          xhr.overrideMimeType("text/json");
          return xhr.setRequestHeader("Accept", "application/json");
        },
        success: (function(_this) {
          return function(data) {
            var error;
            if ((data != null) && data.error) {
              error = {
                'password': data.error
              };
              return new ErrorHandler(error, $form.parent().find(".errors", 'passwordConfirmSuccessError')).generateErrors();
            } else {
              $form.parent().empty();
              events.trigger('event/passwordConfirmSuccess', data);
              $('.reset_success').html(data.success).show();
              return _this._determineClient();
            }
          };
        })(this),
        error: (function(_this) {
          return function(errors) {
            return new ErrorHandler($.parseJSON(errors.responseText), $form.parent().find(".errors", 'passwordConfirmError')).generateErrors();
          };
        })(this)
      });
    };

    Login.prototype._clearInputs = function(formID) {
      var $inputs, $labels;
      $inputs = $(formID + ' input[type="email"]').add($(formID + ' input[type="password"]'));
      $labels = $("#z_form_labels label");
      return $inputs.each(function(index, elem) {
        $(elem).focus(function() {
          return $($labels[index]).hide();
        });
        $(elem).blur(function() {
          if ($(elem).val() === '') {
            return $($labels[index]).show();
          }
        });
        return $($labels[index]).click(function() {
          return $inputs[index].focus();
        });
      });
    };

    Login.prototype._redirectOnSuccess = function(obj, $form) {
      $form.prm_dialog_close();
      if (obj.redirectUrl) {
        return window.location.assign(obj.redirectUrl);
      }
    };

    Login.prototype._toggleSessionState = function() {
      if (this.my.session) {
        this._hideRegister();
        this._showLogout();
        this._showAccount();
        return this._toggleElementsWhenLoggedIn();
      } else {
        this._showRegister();
        this._showLogin();
        return this._toggleElementsWhenLoggedOut();
      }
    };

    Login.prototype._showRegister = function() {
      return $("a.register").parent().removeClass('hidden');
    };

    Login.prototype._hideRegister = function() {
      return $("a.register").parent().addClass('hidden');
    };

    Login.prototype._showAccount = function() {
      if ($.cookie('z_type_email')) {
        return $('a.account').parent().removeClass('hidden');
      }
    };

    Login.prototype._showLogout = function() {
      var $logLink;
      $logLink = $("a.login");
      $logLink.each(function() {
        return this.className = "logout " + this.className;
      });
      $logLink.removeClass("login");
      return $('.link_text', $logLink).text('Log Out');
    };

    Login.prototype._showLogin = function() {
      return $('a.logout .link_text').text('Log In');
    };

    Login.prototype._toggleElementsWhenLoggedIn = function() {
      $(this.hideIfLoggedInSelector).hide();
      return $(this.hideIfLoggedOutSelector).css({
        display: ''
      });
    };

    Login.prototype._toggleElementsWhenLoggedOut = function() {
      $(this.hideIfLoggedInSelector).css({
        display: ''
      });
      return $(this.hideIfLoggedOutSelector).hide();
    };

    Login.prototype._bindForms = function(type) {
      var formID;
      formID = "#zutron_" + type + "_form";
      if (this.MOBILE && $(formID).is(':visible')) {
        this.wireupSocialLinks($(formID));
        this._clearInputs(formID);
      }
      return $("a." + type + ", a.js_" + type).click((function(_this) {
        return function() {
          var $div;
          $('.prm_dialog').prm_dialog_close();
          $div = $(formID);
          if (type === 'account') {
            _this._prefillAccountName($div);
          }
          return _this._triggerModal($div);
        };
      })(this));
    };

    Login.prototype._triggerModal = function($div) {
      new ErrorHandler()._clearErrors($div);
      $div.prm_dialog_open();
      if (this.options.prefillEmailInput && this.my.zmail) {
        $div.find('#email, #auth_key').val(this.my.zmail);
      }
      $div.find(':input').filter(':visible:first').focus();
      $div.on("click", "a.close", function() {
        return $div.prm_dialog_close();
      });
      return this.wireupSocialLinks($div);
    };

    Login.prototype._bindSocialLink = function($link, url, $div) {
      return $link.on("click", (function(_this) {
        return function() {
          _this._stayOrLeave($div);
          return _this._redirectTo(url);
        };
      })(this));
    };

    Login.prototype._stayOrLeave = function($form) {
      var options, staySignedIn;
      staySignedIn = $form.find('input[type="checkbox"]').attr('checked');
      if (staySignedIn) {
        options = {
          path: "/",
          domain: window.location.host
        };
        return $.cookie("stay", "true", options);
      } else {
        return this.expireCookie("sgn");
      }
    };

    Login.prototype._logOut = function(e) {
      var all_cookies;
      e.preventDefault();
      all_cookies = ["provider", "sgn", "zid", "z_type_email"];
      $.each(all_cookies, (function(_this) {
        return function(index, cookie) {
          return _this.expireCookie(cookie);
        };
      })(this));
      return window.location.replace(this.my.currentUrl);
    };

    Login.prototype._redirectTo = function(url) {
      return $.ajax({
        type: "get",
        url: zutron_host + "/ops/heartbeat/riak",
        success: function() {
          return window.location.assign(url);
        },
        error: (function(_this) {
          return function() {
            _this.my.registrationForm.prm_dialog_close();
            $("#zutron_login_form, #zutron_registration").prm_dialog_close();
            return _this._triggerModal($("#zutron_error"));
          };
        })(this)
      });
    };

    Login.prototype._setHiddenValues = function($form) {
      $form.find("input#state").val(this.my.zid);
      return $form.find("input#origin").val(this._encodeURL(window.location.href));
    };

    Login.prototype._determineClient = function() {
      var clients;
      if (this.my.currentUrl.indexOf('client') > 0) {
        clients = ["iOS", "android"];
        return $.each(clients, (function(_this) {
          return function(client) {
            var myClient;
            myClient = _this.my.currentUrl.substring(_this.my.currentUrl.indexOf('client'), location.href.length);
            myClient = myClient.split("=")[1].toLowerCase();
            return _this._createAppButton(myClient);
          };
        })(this));
      } else {
        return $('#reset_return_link').attr('href', "http://" + window.location.host).show();
      }
    };

    Login.prototype._createAppButton = function(client) {
      var btn, launchUrl;
      if (client) {
        launchUrl = "com.primedia.Apartments://settings";
      }
      btn = "<a href='" + launchUrl + "' class='" + client + "_app_button'>Launch ApartmentGuide App</a>";
      return $('#app_container').html(btn);
    };

    Login.prototype._setSessionType = function() {
      return $.cookie('z_type_email', 'profile');
    };

    Login.prototype._setEmail = function(email) {
      this.my.zmail = email;
      return $.cookie('zmail', email);
    };

    Login.prototype._overrideDependencies = function() {
      this.MOBILE = window.location.host.match(/(^m\.|^local\.m\.)/) != null;
      this.BIGWEB = !this.MOBILE;
      if (this.BIGWEB) {
        return this._clearInputs = function() {};
      }
    };

    return Login;

  })();
  return {
    instance: {},
    init: function(options) {
      if (options == null) {
        options = {};
      }
      return this.instance = new Login(options);
    },
    wireupSocialLinks: function() {
      return this.instance.wireupSocialLinks();
    },
    toggleRegistrationDiv: function(div) {
      return this.instance.toggleRegistrationDiv(div);
    },
    expireCookie: function() {
      return this.instance.expireCookie();
    },
    session: function() {
      return this.instance.my.session;
    }
  };
});

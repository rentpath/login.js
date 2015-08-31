define [
  'jquery'
  'primedia_events'
  'login/error_handler'
  'jquery.cookie'
], (
  $
  events
  ErrorHandler
) ->
  class Login

    #
    # Note regarding Ajax response handling:
    # IE (at least versions 8 and 9) only allows access to the response body
    # of cross-domain requests when the response status is 200.
    # In all use cases where we need to communicate specific errors back
    # to the client, the server should return a 200 response that contains the
    # error data in some identifiable way so that this code can determine which "successful"
    # responses are in fact errors.
    #

    hideIfLoggedInSelector:  '.js_hidden_if_logged_in'
    hideIfLoggedOutSelector: '.js_hidden_if_logged_out'

    DEFAULT_OPTIONS = {
      prefillEmailInput: true
      showDialogEventTemplate: 'uiShow{type}Dialog'
      redirectOnLogin: true
    }

    constructor: (options) ->
      @options = $.extend({}, DEFAULT_OPTIONS, options)
      @_overrideDependencies()

      @my =
        zmail:      $.cookie 'zmail'
        zid:        $.cookie 'zid'
        session:    $.cookie("sgn") is "temp" or $.cookie("sgn") is "perm"
        currentUrl: window.location.href
        popupTypes: ["login", "register", "account", "reset", "confirm", "success"]

      $(document).on 'new_zid_obtained', =>
        @my.zid = $.cookie 'zid'

      $(document).ready =>
        @_welcomeMessage()
        @_toggleSessionState()
        @_enableLoginRegistration()

        $.each @my.popupTypes, (index, type) =>
          @_bindForms type

        $(document).on 'click', 'a.logout', (e) =>
          @_logOut e

    _prefillAccountName: ($div) ->
      $.ajax
        type: "GET"
        datatype: 'json'
        url:  "#{zutron_host}/zids/#{@my.zid}/"
        beforeSend: (xhr) ->
          xhr.overrideMimeType "text/json"
          xhr.setRequestHeader "Accept", "application/json"
        success: (data) =>
          $div.find('input[name="new_first_name"]').val(data.zid.user.first_name)
          $div.find('input[name="new_last_name"]').val(data.zid.user.last_name)

    _prefillEmail: ($div) ->
      if @options.prefillEmailInput && @my.zmail
        for selector in ['#email', '#auth_key']
          input = $(selector)
          input.val(@my.zmail) unless input.val()

    _encodeURL: (href) ->
      [path, hash] = href.split('#')
      hash = if hash then encodeURIComponent("##{hash}") else ""
      path + hash

    toggleRegistrationDiv: ($div) ->
      unless @my.session
        @wireupSocialLinks $div.show()
        $.each @my.popupTypes, (index, type) =>
          @_bindForms type

    expireCookie: (cookie) ->
      if cookie
        options =
          expires: new Date(1)
          path: "/"
          domain: ".#{window.location.host}"
        $.cookie cookie, "", options

    wireupSocialLinks: ($div) ->
      baseUrl = "#{zutron_host}?zid_id=#{@my.zid}&referrer=#{encodeURIComponent(@my.currentUrl)}"
      baseUrl += "&realm=#{@options.realm}" if @options.realm
      baseUrl += '&technique='
      fbLink = $div.find("a.icon_facebook48")
      twitterLink = $div.find("a.icon_twitter48")
      googleLink = $div.find("a.icon_google_plus48")
      @_bindSocialLink fbLink, "#{baseUrl}facebook", $div
      @_bindSocialLink twitterLink, "#{baseUrl}twitter", $div
      @_bindSocialLink googleLink, "#{baseUrl}google_oauth2", $div

    _welcomeMessage: ->
      element = $('#welcome_message')
      if element.length > 0
        @_triggerModal element if $.cookie("user_type") is "new"
        @expireCookie "user_type"
        $('a.close').on "click", ->
          element.prm_dialog_close()

    saveUserData: (data, successCallback, errorCallback) ->
      $.ajax
        type: "POST"
        data: data
        datatype: 'json'
        url:  "#{zutron_host}/zids/#{@my.zid}/email_change.json"
        beforeSend: (xhr) ->
          xhr.overrideMimeType "text/json"
          xhr.setRequestHeader "Accept", "application/json"
        success: (response) =>
          if response? and response.errors # IE8 XDR Fallback
            errorCallback(response.errors) if errorCallback
          else
            @_setEmail(data.email)
            events.trigger('event/changeEmailSuccess', response)
            successCallback(response) if successCallback
        error: (errors) =>
          errorCallback($.parseJSON(errors.responseText)) if errorCallback

    resetUserPassword: (data, successCallback, errorCallback) ->
      data = $.param(data) if typeof data is 'object'
      $.ajax
        type: 'POST'
        url: zutron_host + "/password_reset?" + data,
        beforeSend: (xhr) ->
          xhr.overrideMimeType "text/json"
          xhr.setRequestHeader "Accept", "application/json"
        success: (response) =>
          if response? and response.errors # IE8 XDR Fallback
            errorCallback(response.errors) if errorCallback
          else
            events.trigger('event/passwordResetSuccess', data)
            successCallback(response) if successCallback
        error: (errors) =>
          errorCallback($.parseJSON(errors.responseText).errors) if errorCallback

    _enableLoginRegistration: =>
      $('#zutron_register_form form').submit (e) =>
        @_submitEmailRegistration $(e.target)
      $('#zutron_account_form form').submit (e) =>
        @_submitChangeUserData $(e.target)
      $('#zutron_login_form form').submit (e) =>
        @_submitLogin $(e.target)
      $('#zutron_reset_form form').submit (e) =>
        @_submitPasswordReset $(e.target)
      $('#zutron_confirm_form form').submit (e) =>
        @_submitPasswordConfirm $(e.target)

    _submitEmailRegistration: ($form) =>
      @_setHiddenValues $form
      $.ajax
        type: 'POST'
        data: $form.serialize()
        url: "#{zutron_host}/auth/identity/register"
        beforeSend: (xhr) ->
          xhr.overrideMimeType "text/json"
          xhr.setRequestHeader "Accept", "application/json"
        success: (data) =>
          if data['redirectUrl']
            @_stayOrLeave $form
            $("#zutron_login_form, #zutron_registration").prm_dialog_close() if @options.redirectOnLogin
            @_setSessionType()
            @_setEmail $form.find("#email").val()
            events.trigger('event/emailRegistrationSuccess', data)
            $(document).trigger('emailRegistrationSuccess', data)
            @_redirectOnSuccess data, $form if @options.redirectOnLogin
          else # IE8 XDR Fallback
            new ErrorHandler(data, $form.parent().find(".errors"), 'emailRegistrationError').generateErrors()
        error: (errors) =>
          new ErrorHandler($.parseJSON(errors.responseText), $form.parent().find(".errors"), 'emailRegistrationError').generateErrors()

    _submitLogin: ($form) ->
      @_setHiddenValues $form
      $.ajax
        type: "POST"
        data: $form.serialize()
        url:  "#{zutron_host}/auth/identity/callback"
        beforeSend: (xhr) ->
          xhr.overrideMimeType "text/json"
          xhr.setRequestHeader "Accept", "application/json"
        success: (data) =>
          if data['redirectUrl']
            @_stayOrLeave $form
            $("#zutron_login_form, #zutron_registration").prm_dialog_close() if @options.redirectOnLogin
            @_setSessionType()
            @_setEmail $form.find("#auth_key").val()
            events.trigger('event/loginSuccess', data)
            @_redirectOnSuccess data, $form if @options.redirectOnLogin
          else # IE8 XDR Fallback
            new ErrorHandler(data, $form.parent().find(".errors"), 'loginError').generateErrors()
        error: (errors) =>
          new ErrorHandler($.parseJSON(errors.responseText), $form.parent().find(".errors"), 'loginError').generateErrors()

    _submitChangeUserData: ($form)->
      user_data =
        first_name: $('input[name="new_first_name"]').val()
        last_name: $('input[name="new_last_name"]').val()
        email: $('input[name="new_email"]').val()
        email_confirmation: $('input[name="new_email_confirm"]').val()
      onSuccess = =>
        $('#zutron_account_form').prm_dialog_close()
        @_triggerModal $("#zutron_success_form")
      onError = (errors) =>
        new ErrorHandler(errors, $form.parent().find(".errors"), 'changeEmailError').generateErrors()
      @saveUserData(user_data, onSuccess, onError)

    _submitPasswordReset: ($form) ->
      onSuccess = (data) =>
        $form.parent().empty()
        $('.reset_success').html(data.success).show()
      onError = (errors) =>
        new ErrorHandler(errors, $form.parent().find(".errors"), 'passwordResetError').generateErrors()
      @resetUserPassword($form.serialize(), onSuccess, onError)

    _submitPasswordConfirm: ($form) ->
      $.ajax
        type: 'POST'
        data: $form.serialize()
        url: "#{zutron_host}/password_confirmation"
        beforeSend: (xhr) ->
          xhr.overrideMimeType "text/json"
          xhr.setRequestHeader "Accept", "application/json"
        success: (data) =>
          if data? and data.error # IE8 XDR Fallback
            error = {'password': data.error}
            new ErrorHandler(error, $form.parent().find(".errors"), 'passwordConfirmError').generateErrors()
          else
            $form.parent().empty()
            events.trigger('event/passwordConfirmSuccess', data)
            $('.reset_success').html(data.success).show()
            @_determineClient()
        error: (errors) =>
          new ErrorHandler($.parseJSON(errors.responseText), $form.parent().find(".errors"), 'passwordConfirmError').generateErrors()

    _clearInputs: (formID) ->
      $inputs = $(formID + ' input[type="email"]').add $(formID + ' input[type="password"]')
      $labels = $("#z_form_labels label")
      $inputs.each (index, elem) ->
        $(elem).focus ->
          $($labels[index]).hide()
        $(elem).blur ->
          if $(elem).val() is ''
            $($labels[index]).show()
        $($labels[index]).click ->
          $inputs[index].focus()

    _redirectOnSuccess: (obj, $form) ->
      $form.prm_dialog_close()
      window.location.assign obj.redirectUrl if obj.redirectUrl

    _toggleSessionState: ->
      if @my.session
        @_hideRegister()
        @_showLogout()
        @_showAccount()
        @_toggleElementsWhenLoggedIn()
      else
        @_showRegister()
        @_showLogin()
        @_toggleElementsWhenLoggedOut()

    _showRegister: ->
      $("a.register").parent().removeClass 'hidden'

    _hideRegister: ->
      $("a.register").parent().addClass 'hidden'

    _showAccount: ->
      $('a.account').parent().removeClass 'hidden' if $.cookie 'z_type_email'

    _showLogout: ->
      $logLink = $("a.login")
      # Add class to beginning to ensure it's picked up by autotagging
      $logLink.each ->
        @className = "logout #{@className}"
      $logLink.removeClass("login")
      $('.link_text',$logLink).text('Log Out')

    _showLogin: ->
      $('a.logout .link_text').text('Log In')

    _toggleElementsWhenLoggedIn: ->
      $(@hideIfLoggedInSelector).hide()
      $(@hideIfLoggedOutSelector).css display: ''

    _toggleElementsWhenLoggedOut: ->
      $(@hideIfLoggedInSelector).css display: ''
      $(@hideIfLoggedOutSelector).hide()

    _bindForms: (type) ->
      formID = "#zutron_#{type}_form"
      $form  = $(formID)
      if @MOBILE
        if $form.is(':visible')
          @wireupSocialLinks $form
          @_clearInputs formID
          @_prefillEmail $form
      else
        eventType = type.charAt(0).toUpperCase() + type.slice(1)
        showEvent = @options.showDialogEventTemplate.replace('{type}', eventType)
        $(document).on showEvent, =>
          $('.prm_dialog:visible').prm_dialog_close()
          @_prefillAccountName($form) if type is 'account'
          @_triggerModal $form
        $("a.#{type}, a.js_#{type}").click ->
          $(document).trigger $.Event(showEvent, relatedTarget: @)
        $form.on "click", "a.close", ->
          $form.prm_dialog_close()

    _triggerModal: ($div) =>
      new ErrorHandler().clearErrors $div
      $div.prm_dialog_open()
      @_prefillEmail($div)
      $div.find(':input').filter(':visible:first').focus()
      @wireupSocialLinks $div

    _bindSocialLink: ($link, url, $div) ->
      $link.on "click", =>
        @_stayOrLeave $div
        @_redirectTo url

    _stayOrLeave: ($form) ->
      staySignedIn = $form.find('input[type="checkbox"]').attr('checked')
      if staySignedIn
        options =
          path: "/",
          domain: window.location.host
        $.cookie "stay", "true", options
      else
        @expireCookie "sgn"

    _logOut: (e) ->
      e.preventDefault()
      all_cookies =  ["provider", "sgn", "zid", "z_type_email"]
      $.each all_cookies, (index, cookie) =>
        @expireCookie cookie
      window.location.reload(true)

    _redirectTo: (url) ->
      $.ajax
        type: "GET"
        url: zutron_host + "/ops/heartbeat"
        success: ->
          window.location.assign url
        error: =>
          @my.registrationForm.prm_dialog_close()
          $("#zutron_login_form, #zutron_registration").prm_dialog_close()
          @_triggerModal $("#zutron_error")

    _setHiddenValues: ($form) ->
      $form.find("input#state").val @my.zid
      $form.find("input#origin").val @_encodeURL(window.location.href)

    _determineClient: ->
      if @my.currentUrl.indexOf('client') > 0
        clients = ["iOS", "android"]
        $.each clients, (client) =>
          myClient = @my.currentUrl.substring(@my.currentUrl.indexOf('client'), location.href.length)
          myClient = myClient.split("=")[1].toLowerCase()
          @_createAppButton myClient
      else
        $('#reset_return_link').attr('href', "http://#{window.location.host}").show()

    _createAppButton: (client) ->
      launchUrl = "com.primedia.Apartments://settings" if client
      btn = "<a href='#{launchUrl}' class='#{client}_app_button'>Launch ApartmentGuide App</a>"
      $('#app_container').html btn

    _setSessionType: () ->
      $.cookie 'z_type_email', 'profile' #user registered by email

    _setEmail: (email) ->
      @my.zmail = email
      $.cookie 'zmail', email, { path: '/' }

    _overrideDependencies: ->
      @MOBILE = window.location.host.match(/(^m\.|^local\.m\.)/)?
      @BIGWEB = not @MOBILE
      if @BIGWEB
        @_clearInputs = ->

  instance: {}
  init: (options = {}) -> @instance = new Login(options)
  wireupSocialLinks: -> @instance.wireupSocialLinks()
  toggleRegistrationDiv: (div) -> @instance.toggleRegistrationDiv(div)
  saveUserData: -> @instance.saveUserData.apply(@instance, arguments)
  resetUserPassword: -> @instance.resetUserPassword.apply(@instance, arguments)
  expireCookie: -> @instance.expireCookie()
  session: -> @instance.my.session

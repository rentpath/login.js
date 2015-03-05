# Karma configuration
# Generated on Fri Feb 27 2015 12:34:24 GMT-0700 (MST)

module.exports = (config) ->
  config.set

    # base path that will be used to resolve all patterns (eg. files, exclude)
    basePath: ''


    # frameworks to use
    # available frameworks: https://npmjs.org/browse/keyword/karma-adapter
    frameworks: ['jasmine', 'requirejs']

    # list of files / patterns to load in the browser
    files: [
      # Dependencies
      {pattern: 'vendor/bower/jquery/jquery.js', watched: false, served: true, included: true}
      {pattern: 'vendor/bower/jasmine-jquery/lib/jasmine-jquery.js', watched: false, served: true, included: true}

      # Loaded with require
      {pattern: 'vendor/bower/jquery.cookie/**/*.js', watched: false, included: false}
      {pattern: 'vendor/bower/primedia_events/**/*.js', watched: false, included: false}

      # Misc
      {pattern: 'dist/*.js', included: false, served:true}
      {pattern: 'test/**/*_spec.coffee', included: false}
      {pattern: 'test/fixtures/*.html', watched: true, served: true, included: false}
      'test-main.coffee'
    ]


    # list of files to exclude
    exclude: [
    ]


    # preprocess matching files before serving them to the browser
    # available preprocessors: https://npmjs.org/browse/keyword/karma-preprocessor
    preprocessors: {
      '**/*.coffee': ['coffee']
    }


    # test results reporter to use
    # possible values: 'dots', 'progress'
    # available reporters: https://npmjs.org/browse/keyword/karma-reporter
    reporters: ['progress']


    # web server port
    port: 9876


    # enable / disable colors in the output (reporters and logs)
    colors: true


    # level of logging
    # possible values:
    # - config.LOG_DISABLE
    # - config.LOG_ERROR
    # - config.LOG_WARN
    # - config.LOG_INFO
    # - config.LOG_DEBUG
    logLevel: config.LOG_INFO


    # enable / disable watching file and executing tests whenever any file changes
    autoWatch: true


    # start these browsers
    # available browser launchers: https://npmjs.org/browse/keyword/karma-launcher
    browsers: ['Chrome']


    # Continuous Integration mode
    # if true, Karma captures browsers, runs the tests and exits
    singleRun: false

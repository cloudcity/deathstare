class ConcurrentInstances

  actual: 0
  requested: null
  button: null
  lastChangeAt: new Date()
  timer: null
  actualElemSelector: '#concurrent_instances_actual'
  requestedElemSelector: '#concurrent_instances_requested'
  formSelector: '#concurrent-instances-form'

  constructor: ->
    @concurrentInstancesSmartPoller()

  getConcurrentInstances: ->
    $.getJSON('/concurrent_instances',(data) =>
      if @actual != data.actual
        @actual = data.actual
        @lastChangeAt = new Date()
      if @button
        if @actual != @requested && @button.isLoading()
          @button.setProgress(1 - Math.abs(@requested - @actual) / @requested)
        else
          @button.stop()
      @updateDial()
      if @requested is null # first time through set requested to actual
        @requested = @actual
        @updateDial(@requestedElemSelector)
    ).error(@handleErrors.bind(this))

  updateDial: (selector) ->
    selector = @actualElemSelector unless selector  # default to updating actual
    if $(selector).length != 0
      $(selector).val(@actual).trigger('change')

  setSubmitHook: ->
    @button = Ladda.create $('#make-it-so-button')[0]
    $(@formSelector).submit((event) =>
      @setConcurrentInstances $(@requestedElemSelector).val()
      event.preventDefault()
      false
    )

  setConcurrentInstances: (v) ->
    @requested = parseInt(v)
    @button.start() if @button
    $.ajax(
      type: 'PATCH',
      url: '/concurrent_instances',
      data: {requested: v},
      dataType: 'json'
    ).success(=>
      @lastChangeAt = new Date()
    ).error(@handleErrors.bind(this))

  handleErrors: (xhr) ->
    # If we don't stop polling we just keep getting errors...
    @canceled = true

    try
      text = JSON.parse(xhr.responseText)
      text = text.error
    catch err
      text = 'Oops! Something went wrong.'
      console.log('Unrecognized response: ' + xhr.responseText)

    copy = $('.js-alert-error-template').clone().insertBefore('.js-templates')
    copy.find('span').text(text).show()
    copy.show()

  # Inspirational credits go to: https://github.com/blog/467-smart-js-polling
  # Polls every 3 seconds for 30 seconds since the last change at, then slows to
  # every 20 seconds for 100 seconds, then to 60 seconds
  # The Heroku API Rate limit is 1200 reqs/hour
  concurrentInstancesSmartPoller: ->
    return if @canceled or window.stopSmartPoller
    @getConcurrentInstances()
    now = new Date
    secsSinceLastChange = (now - @lastChangeAt) / 1000

    if secsSinceLastChange <= 30
      setTimeout (=> @concurrentInstancesSmartPoller()), 3000
    else if secsSinceLastChange > 30 && secsSinceLastChange <= 100
      setTimeout (=> @concurrentInstancesSmartPoller()), 20000
    else
      setTimeout (=> @concurrentInstancesSmartPoller()), 60000

if document.location.pathname is '/'
  concurrentInstances = new ConcurrentInstances()
else
  concurrentInstances = null

$ ->
  if concurrentInstances
    $(".dial").knob()

    concurrentInstances.updateDial()
    concurrentInstances.setSubmitHook()

  # for debugging
  window.stopSmartPoller = $('body').data('environment') != 'production'


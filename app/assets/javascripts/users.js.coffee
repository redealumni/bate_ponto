# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/
$(->

  main = $('.shifts-section')

  parse_to_minutes = (value) ->
    hm = value.split(':')
    return (parseInt(hm[0]) * 60) + parseInt(hm[1])

  to_date = (seconds) ->
    t = new Date(1970,0,1)
    t.setSeconds(seconds)
    return t

  # parseToString = (value) ->
  #  return (value / 60) + ':' + (value % 60)

  parsed_shifts = [];
  if $('#__shifts')
    parsed_shifts = $('#__shifts').children().val().
      slice(1, -1).split(',').map (e) -> parseInt(e) * 60

  shift_time_settings = { timeFormat: "H:i" }
  shift_lunch_settings = { timeFormat: "H:i", maxTime: '2:00', step: 15}

  enable_time_picker = (selector) ->
    return (idx, input) ->
      jinput = $(input)
      settings = if jinput.data('shift-time') then shift_time_settings else shift_lunch_settings
      jinput.timepicker(settings).timepicker('setTime', selector(idx, input))

  set_time_startup = (idx, input) ->
    to_date(parsed_shifts[idx])

  set_time_new = (idx, input) ->
    to_date(parse_to_minutes($(input).val()) * 60)

  # Enable time-picker at startup
  $('.shift :input', main).each(enable_time_picker(set_time_startup))

  # New shift option
  $('#add-shift', main).click () ->
    last_shift = $('#shift-list', main).children().last()
    new_index = parseInt(last_shift.data('shift-num')) + 1
    new_shift = last_shift.clone()

    entrance_txt = "#{new_index}-1"
    exit_txt = "#{new_index}-2"
    lunch_txt = "#{new_index}-lunch"
    new_shift.find('label, input').each (idx, e) ->
      je = $(e)
      subst = switch 
          when je.data('shift-entrance') then entrance_txt
          when je.data('shift-exit') then exit_txt
          when je.data('shift-lunch') then lunch_txt
      if je.is('label')
        e.for = subst
      else if je.is('input')
        e.id = e.name = subst

    new_shift.data('shift-num', new_index)
    new_shift.find('.shift-intro').children().html("<strong>Turno #{new_index}:</strong>")
    new_shift.appendTo last_shift.parent()

    new_shift.find(':input').each(enable_time_picker(set_time_new))

    $('#num-of-shifts', main).val(new_index)

    if new_index >= 2
      $('#remove-shift', main).show()

  # Remove shift option
  $('#remove-shift', main).click () ->
    to_remove = $('#shift-list', main).children().last().remove()
    new_index = parseInt($('#num-of-shifts', main).val()) - 1
    $('#num-of-shifts', main).val(new_index)

    if new_index < 2
      $('#remove-shift', main).hide()

  # Submit action
  $('form').submit () ->
    shifts = []
    inputs = $('.shift :input', main)
    inputs.each (idx, input) ->
      shifts.push parse_to_minutes(input.value)
    $('#__shifts').children().val(JSON.stringify(shifts))
    return

)
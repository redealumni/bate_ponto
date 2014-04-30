# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/
$(->

  shift_main = $('.shifts-section')
  goals_main = $('.goals-section')

  day_mapping =
    monday: 1
    thursday: 2
    wednesday: 3
    tuesday: 4
    friday: 5

  num_mapping =
    1: 'monday'
    2: 'thursday'
    3: 'wednesday'
    4: 'tuesday'
    5: 'friday'

  parse_goals = (array) ->
    array.sort (a, b) -> a[0] - b[0]
    array.map (pair) -> pair[1]    

  parse_to_minutes = (value) ->
    hm = value.split(':')
    return (parseInt(hm[0]) * 60) + parseInt(hm[1])

  parse_to_hours = (value) ->
    hm = value.split(':')
    return parseInt(hm[0]) + parseInt(hm[1]) / 60

  to_date = (minutes) ->
    t = new Date(1970,0,1)
    t.setSeconds(minutes * 60)
    return t

  to_minutes = (hours) ->
    Math.round(hours * 60)

  to_hash = (array) ->
    result = {}
    array.forEach (pair) ->
      [day, shifts] = pair
      result[day_mapping[day]] = shifts
    return result

  to_array = (hash) ->
    result = []
    for day, shifts of hash
      result.push [num_mapping[day], shifts]
    return result

  # parseToString = (value) ->
  #  return (value / 60) + ':' + (value % 60)

  $('#trueShifts').each (idx, elem) ->
    $('#__shifts').children().val($(elem).text())

  goals = []

  $('#trueGoals').each (idx, elem) ->
    trueValue = $(elem).text()
    $('#__goals').children().val(trueValue)
    goals = JSON.parse(trueValue)

  parsed_shifts = {};
  $('#__shifts').children().each (idx, shifts) ->
    obj = JSON.parse(shifts.value)
    parsed_shifts = to_hash(obj)

  shift_time_settings = { timeFormat: 'H:i' }
  shift_lunch_settings = { timeFormat: 'H:i', maxTime: '2:00', step: 15}
  goal_settings = { timeFormat: 'H:i', maxTime: '10:00', step: 60 }

  enable_goal_time_picker = (idx, input) ->
    $(input).timepicker(goal_settings).timepicker('setTime', to_date(to_minutes(goals[idx])))

  enable_shift_time_picker = (setter) ->
    return (idx, input) ->
      jinput = $(input)
      settings = if jinput.data('shift-lunch') then shift_lunch_settings else shift_time_settings
      jinput.timepicker(settings).timepicker('setTime', setter(idx, input))

  set_time_startup = (day_id, shift_id) ->
    return (idx, input) ->
      to_date(parsed_shifts[day_id][shift_id][input.id])

  set_time_new = (idx, input) ->
    to_date(parse_to_minutes(input.value))

  # Hide goals option if flexible
  toggle_goals_section = (flexible) ->
    if flexible
      goals_main.hide()
    else
      goals_main.show()

  $('#user_flexible_goal').change () ->
    toggle_goals_section $(this).is(':checked')

  toggle_goals_section $('#user_flexible_goal').is(':checked')

  # Enable time-picker at startup
  $('.goals-line :input', goals_main).each enable_goal_time_picker

  $('.shift-list', shift_main).each (idx, list) ->
    list = $(list)
    day_id = list.data('shift-day')
    $('.shift', list).each (idx, shift) ->
      shift = $(shift)
      shift_id = shift.data('shift-num') - 1
      $(':input', shift).each enable_shift_time_picker(set_time_startup(day_id, shift_id))

  # New shift option
  $('.add-shift-btn', shift_main).click (e) ->
    self = $(this)
    shift_day = self.parent().data('shift-day')
    last_shift = $('.shift', self.parent()).last()
    new_index = parseInt(last_shift.data('shift-num')) + 1
    new_shift = last_shift.clone()

    new_shift.data('shift-num', new_index)
    new_shift.find('.shift-intro').children().html """
      <strong>Turno #{new_index}:</strong>
    """

    last_shift.after new_shift

    new_shift.find(':input').each enable_shift_time_picker(set_time_new)
    $("#num-of-shifts-#{shift_day}", shift_main).val(new_index)

    if new_index >= 2
      $('.remove-shift-btn', self.parent()).show()

  # Remove shift option
  $('.remove-shift-btn', shift_main).click (e) ->
    self = $(this)
    shift_day = self.parent().data('shift-day')
    old_index = $("#num-of-shifts-#{shift_day}", shift_main)
    new_index = parseInt(old_index.val()) - 1
    old_index.val(new_index)

    $('.shift', self.parent()).last().remove()

    if new_index < 2
      self.hide()

  # Submit action
  $('form').submit () ->
    # Goals
    final_goals = []
    $('.goals-section :input').each (idx, input) ->
      final_goals.push [input.id, parse_to_hours(input.value)]
    final_goals = JSON.stringify(parse_goals(final_goals))
    $('#__goals').children().val(final_goals)

    # Shifts
    shifts = {}
    lists = $('.shift-list', shift_main)
    lists.each (idx, list) ->
      list = $(list)
      shift_day = list.data('shift-day')
      shifts[shift_day] = [];
      list.find('.shift').each (idx, shift) ->
        new_shift = {}
        $(shift).find(':input').each (idx, input) -> 
          new_shift[input.id] = parse_to_minutes(input.value)
        shifts[shift_day].push new_shift

    $('#__shifts').children().val(JSON.stringify(to_array(shifts)))
    return

)
# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/
$(->

  shift_main = $('.shifts-section')

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

  to_date = (seconds) ->
    t = new Date(1970,0,1)
    t.setSeconds(seconds)
    return t

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

  parsed_shifts = {};
  $('#__shifts').each (shifts) ->
    obj = JSON.parse(shifts.value)
    parsed_shifts = to_hash(obj)

  shift_time_settings = { timeFormat: 'H:i' }
  shift_lunch_settings = { timeFormat: 'H:i', maxTime: '2:00', step: 15}

  enable_time_picker = (selector) ->
    return (idx, input) ->
      jinput = $(input)
      settings = if jinput.data('shift-time') then shift_time_settings else shift_lunch_settings
      jinput.timepicker(settings).timepicker('setTime', selector(idx, input))

  set_time_startup = (day_id) ->
    return (idx, input) ->
      to_date(parsed_shifts[day_id][idx])

  set_time_new = (day_id) ->
    return (idx, input) ->
      to_date(parse_to_minutes($(input).val()) * 60)

  # Enable time-picker at startup
  $('.shift', shift_main).each (idx, list) ->
    list = $(list)
    $(':input', list).each enable_time_picker(set_time_startup(list.data('shift-day')))

  # New shift option
  $('.add-shift-btn', shift_main).click () ->
    this = $(this)
    shift_day = this.parent().data('shift-day')
    last_shift = $('.shift', this.parent()).last()
    new_index = parseInt(last_shift.data('shift-num')) + 1
    new_shift = last_shift.clone()

    new_shift.data('shift-num', new_index)
    new_shift.find('.shift-intro').children().html """
      <strong>Turno #{new_index}:</strong>
    """

    last_shift.after new_shift

    new_shift.find(':input').each enable_time_picker(set_time_new(shift_day))

    $("#num-of-shifts-#{shift_day}", shift_main).val(new_index)

    if new_index >= 2
      $("#remove-shift-#{shift_day}", shift_main).show()

  # Remove shift option
  $('.remove-shift-btn', shift_main).click () ->
    this = $(this)
    shift_day = this.parent().data('shift-day')
    old_index = $("#num-of-shifts-#{shift_day}", shift_main)
    new_index = parseInt(old_index.val()) - 1
    old_index.val(new_index)

    $('.shift', this.parent()).last().remove()

    if new_index < 2
      $('#remove-shift', shift_main).hide()

  # Submit action
  $('form').submit () ->
    # Goals
    goals = []
    $('.goals-section :input').each (idx, input) ->
      goals.push [input.id, parseInt(input.value)]
    $('#__goals').children().val(JSON.stringify(parse_goals(goals)))

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
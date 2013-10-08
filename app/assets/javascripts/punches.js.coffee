# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/
$(->
  
    #Login show/hide
    
    login_fields = $('#user_login.logged_in')
    login_fields.remove()
    login_hidden = true
    $('#show_hide_login').click -> 
      if login_hidden
        login_fields.insertAfter $('#login_message')
        $('#show_hide_login').html 'Bater como eu mesmo -'
        login_hidden = false
      else
        login_fields.remove()
        $('#show_hide_login').html 'Bater como outro +'
        login_hidden = true
      return false
        
        
    # Edit punch datetimes
    
    $('#punches').on 'click', '.punch_show_form_link', ->
      parent = $(this).parent('.punch_time_display').hide()
      parent_dom_id = parent.attr('meta-dom-id')
      punch_time_forms.filter('[meta-dom-id="' + parent_dom_id + '"]').insertAfter(parent)
      return false
    $('#punches').on 'click', '.punch_show_display_link', ->
      parent = $(this).parent('.punch_time_form')
      parent.siblings('.punch_time_display').show()
      parent.detach()
      return false
    
    punch_time_forms = $('#punches .punch_time_form').detach()

    #############
    #Token Page
    #############

    #focus fica sempre no input
    $("#punch_user_token").focus()

    #se perde o foco, a gente retorna, com timeout para impedir restricoes de seguranca do browser
    $("#punch_user_token").on "blur", ->
      setTimeout( ->
        $("#punch_user_token").focus()
      1000
      )

    #quando completa a chamada de ajax, exibimos/removemos o punch e voltamos o foco
    $("#new_punch").on "ajax:complete", (e, xhr, opts) ->
      $("#punch_user_token").val('').focus()
      response = $.parseJSON(xhr.responseText)
      if response['create']
        punch = $(response['html']).hide()
        $(".punches").prepend punch
        punch.fadeIn('fast')
        $(".punch_item").last().remove()
      if response['delete']
        $(".punches #punch_" + response['delete']['id']).fadeOut('slow')
      if response['notice']
        notice = $("<div class='flash notice'>" + response['notice'] + "</div>")
        $('body').prepend notice
        setTimeout( ->
          notice.fadeOut 500, ->
            notice.remove()
        5000
        )

)  
  
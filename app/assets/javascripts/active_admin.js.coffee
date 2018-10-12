#= require active_admin/base
#= require activeadmin_addons/all

# Oculta/Ver Filtros
$(document).ready ->
  $('a').on 'click', ->
    tma = Date.now()
    tmp = $(this).data('pulsado')
    if tmp
      if tma - parseInt(tmp) < 500
        alert $('#current_user > a').text() + ' ¡Pulse una sola vez!'
        false
      else
        $(this).data 'pulsado', tma
        true
    else
      $(this).data 'pulsado', tma
      true
  $('a#ocultar_ver_side_bar').on 'click', ->
    if $('#main_content').css('margin-right') == '10px'
      # Mostrar
      $('#main_content').css 'margin-right': $('#main_content').data('mr')
      $('#sidebar').show()
      posting = $.get($('#current_user > a').attr('href').replace(/$/, '/filtro'), { 'accion': 'ver' }, 'json')
    else
      $('#main_content').data 'mr', $('#main_content').css('margin-right')
      $('#main_content').css 'margin-right': 10
      $('#sidebar').hide()
      posting = $.get($('#current_user > a').attr('href').replace(/$/, '/filtro'), { 'accion': 'ocultar' }, 'json')
    return
  # Ocultamos los filtros siempre
  if $('#current_user > a').attr('href') != undefined
    if $('#sidebar').length > 0
      $('#main_content').data 'mr', $('#main_content').css('margin-right')
      $('#main_content').css 'margin-right': 10
      $('#sidebar').hide()
      posting = $.get($('#current_user > a').attr('href').replace(/$/, '/filtro'), { 'accion': 'consultar' }, 'json')
      posting.done (data) ->
        if data['respuesta'] == 'S'
          $('#main_content').css 'margin-right': $('#main_content').data('mr')
          $('#sidebar').show()
        return
  return

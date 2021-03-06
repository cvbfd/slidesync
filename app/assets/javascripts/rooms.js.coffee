# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/

class Slide
  # set doc
  constructor: (@id, @doc) ->
    # allowScriptAccess from other domains
    @params = { allowScriptAccess: "always" }
    @atts = { id: "slide" }
    # doc: The path of the file to be used
    # startSlide: The number of the slide to start from
    # rel: Whether to show a screen with related slideshows at the end or not. 0 means false and 1 is true..
    @flashvars = { doc : @doc, startSlide : 1, rel : 0 }

  # Load the flash player. Properties for the player can be changed here.
  loadPlayer: ->
    # Generate the embed SWF file
    swfobject.embedSWF(
      "http://static.slidesharecdn.com/swf/ssplayer2.swf",
      "slide",
      "598",
      "480",
      "8",
      null,
      @flashvars,
      @params,
      @atts,
      => @flashMovie = document.getElementById('slide')
    )

  # Jump to the appropriate slide
  jumpTo: (page) ->
    if page is 'last'
      @flashMovie.last()
    else
      @flashMovie.jumpTo(page)
    $('#gotoBox').val(@currentPage())

  # Update the slide number in the field for the same
  currentPage: ->
    @flashMovie.getCurrentSlide()


class Room
  constructor: (room) ->
    @id = room.id
    $slide_el = $('#slide')
    @slide = new Slide($slide_el.data('id'), $slide_el.data('doc'))

    $('#first').click (e) =>
      e.preventDefault()
      @publishJumpTo 1
    $('#prev').click (e) =>
      e.preventDefault()
      @publishJumpTo @slide.currentPage() - 1
    $('#next').click (e) =>
      e.preventDefault()
      @publishJumpTo @slide.currentPage() + 1
    $('#last').click (e) =>
      e.preventDefault()
      @publishJumpTo 'last'
    $('#gotoBox').keyup (e) =>
      e.preventDefault()
      if e.keyCode is 13
        @publishJumpTo $('#gotoBox').val()

  # publish page move
  publishJumpTo: (page) ->
    url = "/rooms/#{@id}"
    $.post(
      url,
      _method: 'put',
      page: page
    )

  add_user: (user) ->
    $usersList = $('#usersList')
    if $usersList.data('owner') is parseInt(user.id)
      className = 'owner'
    else
      className = 'guest'
    $userItem = $('<li/>').attr(id: "user_#{user.id}", class: className)
    $userItem.append(
      $('<img/>').attr(src: user.info.icon_url)
    ).append(
      user.info.nickname
    ).appendTo($usersList)

  remove_user: (user) ->
    $('#usersList').find("#user_#{user.id}").remove()


jQuery ->
  return null if !$('#stage').data('room')

  room = new Room($('#stage').data('room'))
  room.slide.loadPlayer()

  # websocket
  Pusher.log = (message) ->
    window.console?.log? message
  
  pusher = new Pusher($('#container').data('pusher-key'))
  channel = pusher.subscribe("presence-room-#{room.id}")


  # events
  channel.bind 'jump_to', (page) ->
    room.slide.jumpTo page

  channel.bind 'pusher:subscription_succeeded', (users) ->
    users.each (user) ->
      room.add_user user

  channel.bind 'pusher:member_added', (user) ->
    room.add_user user

  channel.bind 'pusher:member_removed', (user) ->
    room.remove_user user


template = document.querySelector('#template')

polymerLoaded = false

template.announcement = ""

template.status = 'connecting'

template.messages = []

template.users = []

defaultNames = ["Killer Whale", "Giraffe", "Rabbit", "Polar Bear", "Cheetah", "Snow Leopard", "Eagle", "Fox", "Panda", "Salamander", "Jackal", "Elephant ", "Lion", "Horse", "Monkey", "Penguin ", "Wolf", "Dolphin", "Tiger", "Cat", "Shinigami", "Korra", "Aang", "Izumi", "Katara"]

template.userName = prompt "Enter a nick:"

template.avatar = "http://api.adorable.io/avatars/80/" + escape(template.userName) + ".png"

window.addEventListener 'polymer-ready', (e) ->
  polymerLoaded = true

  if template.status == 'connected'
    onconnect()

  # Set focus on the input element.
  $("#input").focus()


sendMessage = (msg)->
  socket.emit 'chat:msg',
    message: msg
    nick: template.userName
    avatar: template.avatar

showMessage = (msg)->
  template.messages.push msg
  template.async ()->
    chatDiv = document.querySelector('.chat-list');
    chatDiv.scrollTop = chatDiv.scrollHeight;

template.sendMyMessage = () ->
  $input = $("#input")

  if socket.socket.connected == false
    alert 'Please wait while we reconnect'
  else if $input.val().trim() != ''
    sendMessage $input.val()
    $input.val ''


template.checkKey = (e) ->
  if e.which == 13
    template.sendMyMessage()
  e.preventDefault()

onconnect = () ->
  template.status = 'connected'
  if polymerLoaded
    socket.emit 'member:connect',
      nick: template.userName
    socket.emit 'chat:demand'
    socket.emit 'announcement:demand'
    socket.emit 'presence:demand'


socket = io.connect document.location.origin,
  reconnectionDelay: 200
  reconnectionDelayMax: 1000
  'sync disconnect on unload': true

socket.on 'connect', onconnect

socket.on 'disconnect', ->
  template.status = 'disconnected'
  socket.emit 'member:disconnect',
    nick: template.userName

socket.on 'reconnect', ->
  template.status = 'connected'
  socket.emit 'member:connect',
    nick: template.userName

socket.on 'chat:msg', (msg)->
  defaultName = defaultNames[(Math.random() * defaultNames.length) >>> 0]
  if msg.invalidNick
    setTimeout () ->
      msg.nick = template.userName = prompt('Sorry! You can\'t have this username.\nPlease enter another username', defaultName) or defaultName
      sendMessage msg.message
    , 1
  else
    showMessage msg

socket.on 'announcement:data', (data)->
  if data['text'].length > 2
    $("#announcement-text")[0].innerHTML = data['text']
    $("#announcement-area")[0].style.display = "block"
  else
    $("#announcement-area")[0].style.display = "none"
  $("#chat-heading")[0].innerHTML = data['heading']
  template.showMembers = data['showMembers']
  document.title = data['pageTitle']

socket.on 'chat:log', (log)->
  log.map showMessage

socket.on 'presence:list', (list)->
  template.users = list

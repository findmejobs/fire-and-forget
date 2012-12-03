dgram = require "dgram"

class ListenServer
  passphrase: ''
  handleMessage: (msg, rinfo) ->
    try
      data = JSON.parse(msg)
      if data and @checkPassphrase(data)
        @incomingData(data)

  checkPassphrase: (data) ->
    if @passphrase == ''
      true
    else
      data.passphrase and data.passphrase == @passphrase

  incomingData: (data) ->
    if data.objectType
      @mongoConnection.collection "fnf-#{data.objectType}", (err, conn) ->
        coll.insert data, {safe:true}, (err) ->

  start: (port) ->
    server = dgram.createSocket("udp4")
    server.on("listening", @onSocketListen)
    server.on("message", @onSocketMessage)
    server.listenServer = this
    server.bind(port)
    @server = server
    this

  stop: ->
    @server.close()

  onSocketListen: ->
    console.log "server listening #{@address().address}:#{@address().port}"

  onSocketMessage: (msg, rinfo) ->
    # Handle the message in the scope of ListenServer, not the Socket
    # This makes it easier to test by spying/stubbing handleMessage instead
    @listenServer.handleMessage(msg, rinfo)

module.exports = ListenServer

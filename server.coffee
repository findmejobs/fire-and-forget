dgram = require 'dgram'
mongodb = require 'mongodb'

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
      @database().collection "fnf-#{data.objectType}", (err, coll) ->
        delete data.passphrase
        delete data.objectType
        coll.insert data, {safe:true}, (err) ->
          console.log err

  databaseServer: ->
    @databaseServerObj ||= new mongodb.Server('127.0.0.1', 27017, {})

  database: ->
    @databaseObj ||= new mongodb.Db('test', @databaseServer(), {w: 1})

  start: (port) ->
    server = dgram.createSocket 'udp4'
    # server.on("listening", @onSocketListen)
    server.on("message", @onSocketMessage)
    server.listenServer = this
    server.bind(port)
    @server = server
    this

  stop: ->
    @server.close()

  # onSocketListen: ->
  #   console.log "server listening #{@address().address}:#{@address().port}"

  onSocketMessage: (msg, rinfo) ->
    # Handle the message in the scope of ListenServer, not the Socket
    # This makes it easier to test by spying/stubbing handleMessage instead
    @listenServer.handleMessage(msg, rinfo)

module.exports = ListenServer

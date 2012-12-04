dgram = require 'dgram'
mongodb = require 'mongodb'

class ListenServer
  passphrase   : ''
  hostname     : 'localhost'
  dbport       : 27017
  databaseName : 'fireandforget'

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
      databaseObj = @database()
      databaseObj.open (err, conn) ->
        conn.collection "fnf-#{data.objectType}", (err, coll) ->
          delete data.passphrase
          delete data.objectType
          unless data.createdAt
            data.createdAt = new Date()
          coll.insert data, {}, (err) ->
            if err
              console.log err
        conn.close()

  databaseServer: ->
    @databaseServerObj ||= new mongodb.Server(@hostname, @dbport)

  database: (callback) ->
    @databaseObj ||= new mongodb.Db(@databaseName, @databaseServer(), {w:1})

  start: (port) ->
    server = dgram.createSocket 'udp4'
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

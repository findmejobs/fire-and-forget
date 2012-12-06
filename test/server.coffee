assert     = require 'assert'
sinon      = require 'sinon'
dgram      = require 'dgram'
mongodb    = require 'mongodb'
server     = require '../server'
portNumber = 12345

delay = (ms, func) -> setTimeout func, ms

describe 'ListenServer', ->
  listenServer = null
  client = null

  beforeEach (done) ->
    client = dgram.createSocket("udp4")
    listenServer = new server()
    listenServer.quiet = true
    listenServer.start portNumber
    done()

  afterEach ->
    client.close()
    listenServer.stop()

  describe 'messages', ->
    it 'should start up and accept messages', (done) ->
      spy = sinon.spy(listenServer, 'handleMessage')

      message = new Buffer('Some bytes')
      client.send message, 0, message.length, portNumber, 'localhost', (err, bytes) ->
        delay 100, ->
          assert(spy.called)
          listenServer.handleMessage.restore()
          done()

    it 'should silently ignore a buffer of invalid JSON', (done) ->
      spy = sinon.spy(listenServer, 'incomingData')

      message = new Buffer('Some bytes')
      client.send message, 0, message.length, portNumber, 'localhost', (err, bytes) ->
        delay 100, ->
          assert(spy.callCount == 0)
          listenServer.incomingData.restore()
          done()

    it 'should accept a buffer of valid JSON', (done) ->
      spy = sinon.spy(listenServer, 'incomingData')

      data = {
        "Thing": "It's a thing"
      }
      message = new Buffer(JSON.stringify(data))
      client.send message, 0, message.length, portNumber, 'localhost', (err, bytes) ->
        delay 100, ->
          assert(spy.calledOnce)
          listenServer.incomingData.restore()
          done()

  describe 'passphrases', ->
    data = null

    beforeEach ->
      data = {
        "Thing": "It's a thing"
      }

    afterEach ->
      listenServer.setPassphrase = ''

    it 'should go right through if no passphrase is set', (done) ->
      spy = sinon.spy(listenServer, 'incomingData')

      message = new Buffer(JSON.stringify(data))
      client.send message, 0, message.length, portNumber, 'localhost', (err, bytes) ->
        delay 100, ->
          assert(spy.calledOnce)
          listenServer.incomingData.restore()
          done()

    it 'should silently fail if the passphrase is not correct', (done) ->
      spy = sinon.spy(listenServer, 'incomingData')
      listenServer.passphrase = '123456'

      message = new Buffer(JSON.stringify(data))
      client.send message, 0, message.length, portNumber, 'localhost', (err, bytes) ->
        delay 100, ->
          assert(spy.callCount == 0)
          listenServer.incomingData.restore()
          done()

    it 'should get through if the passphrase is correct', (done) ->
      spy = sinon.spy(listenServer, 'incomingData')
      listenServer.passphrase = '123456'
      data.passphrase = '123456'

      message = new Buffer(JSON.stringify(data))
      client.send message, 0, message.length, portNumber, 'localhost', (err, bytes) ->
        delay 100, ->
          assert(spy.calledOnce)
          listenServer.incomingData.restore()
          done()

  describe 'mongodb', ->
    it 'should ignore data without an objectType', (done) ->
      spy = sinon.spy(mongodb.Db.prototype, 'collection')
      data =
        'otherData'  : 'Something'

      message = new Buffer(JSON.stringify(data))
      client.send message, 0, message.length, portNumber, 'localhost', (err, bytes) ->
        delay 100, ->
          assert(spy.callCount == 0)
          mongodb.Db.prototype.collection.restore()
          done()

    it 'should use the objectType for the colleciton name', (done) ->
      sinon.stub(mongodb.Db.prototype, 'open').yields(null, listenServer.database())
      sinon.stub(mongodb.Db.prototype, 'collection')
      data =
        'objectType' : 'User'
        'otherData'  : 'Something'

      message = new Buffer(JSON.stringify(data))
      client.send message, 0, message.length, portNumber, 'localhost', (err, bytes) ->
        delay 100, ->
          assert(mongodb.Db.prototype.collection.called, "collection not called")

          dataArg = mongodb.Db.prototype.collection.args[0][0]
          assert(dataArg == 'User')
          mongodb.Db.prototype.collection.restore()
          mongodb.Db.prototype.open.restore()
          done()

    it 'should insert createdAt timestamp if not given', (done) ->
      sinon.stub(mongodb.Db.prototype, 'open').yields(null, listenServer.database())
      sinon.stub(mongodb.Collection.prototype, 'insert')
      data =
        'objectType' : 'User'
        'otherData'  : 'Something'

      message = new Buffer(JSON.stringify(data))
      client.send message, 0, message.length, portNumber, 'localhost', (err, bytes) ->
        delay 100, ->
          dataArg = mongodb.Collection.prototype.insert.args[0][0]
          assert(dataArg.hasOwnProperty('createdAt'))

          mongodb.Collection.prototype.insert.restore()
          mongodb.Db.prototype.open.restore()
          done()

    it 'should remove the passphrase and objectType from the data before inserting', (done) ->
      sinon.stub(mongodb.Db.prototype, 'open').yields(null, listenServer.database())
      sinon.stub(mongodb.Collection.prototype, 'insert')
      data =
        'objectType' : 'User'
        'otherData'  : 'Something'

      message = new Buffer(JSON.stringify(data))
      client.send message, 0, message.length, portNumber, 'localhost', (err, bytes) ->
        delay 100, ->
          dataArg = mongodb.Collection.prototype.insert.args[0][0]

          assert(dataArg.hasOwnProperty('otherData'))
          assert(!dataArg.hasOwnProperty('objectType'))
          assert(!dataArg.hasOwnProperty('passphrase'))

          mongodb.Collection.prototype.insert.restore()
          mongodb.Db.prototype.open.restore()
          done()

    it 'inserts the data given if all other things are good', (done) ->
      sinon.stub(mongodb.Db.prototype, 'open').yields(null, listenServer.database())
      sinon.stub(mongodb.Collection.prototype, 'insert')
      data =
        'objectType' : 'User'
        'oneThing'   : 'Thing'
        'otherData'  : 'Something'

      message = new Buffer(JSON.stringify(data))
      client.send message, 0, message.length, portNumber, 'localhost', (err, bytes) ->
        delay 100, ->
          dataArg = mongodb.Collection.prototype.insert.args[0][0]
          assert(dataArg.oneThing == 'Thing')
          assert(dataArg.otherData == 'Something')
          mongodb.Collection.prototype.insert.restore()
          mongodb.Db.prototype.open.restore()
          done()

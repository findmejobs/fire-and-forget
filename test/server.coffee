assert     = require 'assert'
sinon      = require 'sinon'
dgram      = require 'dgram'
server     = require '../server'
portNumber = 12345

delay = (ms, func) -> setTimeout func, ms

describe 'ListenServer', ->
  listenServer = null
  client = null

  beforeEach (done) ->
    client = dgram.createSocket("udp4")
    listenServer = new server()
    listenServer.start(portNumber)
    done()

  afterEach (done) ->
    client.close()
    listenServer.stop()
    done()

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
    data = {
      "Thing": "It's a thing"
    }

    afterEach (done) ->
      listenServer.setPassphrase = ''
      delete data.passphrase
      done()

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


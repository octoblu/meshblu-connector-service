{describe,beforeEach,afterEach,it} = global
{expect}      = require 'chai'
sinon         = require 'sinon'
shmock        = require 'shmock'
request       = require 'request'
enableDestroy = require 'server-destroy'
Server        = require '../../src/server'

describe 'Generate OTP', ->
  beforeEach (done) ->
    @meshblu = shmock 0xd00d
    enableDestroy @meshblu
    @meshbluOTPService = shmock 0xbabe
    enableDestroy @meshbluOTPService

    @logFn = sinon.spy()
    serverOptions =
      port: undefined,
      disableLogging: true
      logFn: @logFn
      fileDownloaderUrl: "http://localhost:0"
      githubApiUrl: "http://localhost:0"
      meshbluOTPUrl: "http://localhost:#{0xbabe}"
      githubToken: 'some-github-token'
      meshbluConfig:
        hostname: 'localhost'
        protocol: 'http'
        resolveSrv: false
        port: 0xd00d

    @server = new Server serverOptions

    @server.run =>
      @serverPort = @server.address().port
      done()

  afterEach ->
    @meshblu.destroy()
    @server.destroy()
    @meshbluOTPService.destroy()

  describe 'On POST /connectors/:uuid/otp', ->
    describe 'when it is successful', ->
      beforeEach (done) ->
        userAuth = new Buffer('some-uuid:some-token').toString 'base64'

        @authDevice = @meshblu
          .post '/authenticate'
          .set 'Authorization', "Basic #{userAuth}"
          .reply 204

        @getDevice = @meshblu
          .get '/v2/devices/some-device-uuid'
          .set 'Authorization', "Basic #{userAuth}"
          .reply 200, {
            uuid: 'some-device-uuid'
          }

        options =
          uri: '/connectors/some-device-uuid/otp'
          baseUrl: "http://localhost:#{@serverPort}"
          auth:
            username: 'some-uuid'
            password: 'some-token'
          json: true

        request.post options, (error, @response, @body) =>
          done error

      it 'should return a 201', ->
        expect(@response.statusCode).to.equal 201, @body

      it 'should auth the request with meshblu', ->
        @authDevice.done()

      it 'should get the connector device', ->
        @getDevice.done()

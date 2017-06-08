{describe,beforeEach,afterEach,it} = global
{expect}      = require 'chai'
shmock        = require '@octoblu/shmock'
request       = require 'request'
Redis         = require 'ioredis'
uuid          = require 'uuid'
enableDestroy = require 'server-destroy'
Server        = require '../../src/server'

describe 'Generate Otp', ->
  beforeEach (done) ->
    @redisKeyPrefix = "#{uuid.v1()}:"
    @redis = new Redis 'localhost', {
      keyPrefix: @redisKeyPrefix
      dropBufferSupport: true
    }
    @redis.on 'ready', done

  beforeEach (done) ->
    @meshblu = shmock 0xd00d
    enableDestroy @meshblu
    @meshbluOtpService = shmock 0xbabe
    enableDestroy @meshbluOtpService
    @githubService = shmock 0xdead
    enableDestroy @githubService

    serverOptions =
      port: undefined,
      disableLogging: true
      fileDownloaderUrl: "http://localhost:0"
      githubApiUrl: "http://localhost:#{0xdead}"
      meshbluOtpUrl: "http://localhost:#{0xbabe}"
      githubToken: 'some-github-token'
      redisUri: 'localhost'
      redisKeyPrefix: @redisKeyPrefix
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
    @meshbluOtpService.destroy()
    @githubService.destroy()

  describe 'On POST /connectors/:uuid/otp', ->
    describe 'when it is successful', ->
      beforeEach (done) ->
        deviceAuth = new Buffer('some-device-uuid:some-device-token').toString 'base64'
        newDeviceAuth = new Buffer('some-device-uuid:some-new-device-token').toString 'base64'

        @authDevice = @meshblu
          .post '/authenticate'
          .set 'Authorization', "Basic #{deviceAuth}"
          .reply 204

        @getDevice = @meshblu
          .get '/v2/devices/some-device-uuid'
          .set 'Authorization', "Basic #{deviceAuth}"
          .reply 200, {
            uuid: 'some-device-uuid'
            connector: 'meshblu-connector-hue-light'
            connectorMetadata:
              version: '1.00000'
              githubSlug: 'octoblu/meshblu-connector-hue-light'
              meshblu:
                domain: 'some-domain'
          }

        @resolveInstallerVersion = @githubService
          .get '/repos/octoblu/go-meshblu-connector-installer/releases/latest'
          .set 'Authorization', 'token some-github-token'
          .reply 200, { tag_name: 'v20.00' }

        @resolveIgnitionVersion = @githubService
          .get '/repos/octoblu/go-meshblu-connector-ignition/releases/latest'
          .set 'Authorization', 'token some-github-token'
          .reply 200, { tag_name: 'v02.00' }

        @generateToken = @meshblu
          .post '/devices/some-device-uuid/tokens'
          .set 'Authorization', "Basic #{deviceAuth}"
          .reply 201, {
            uuid: 'some-device-uuid'
            token: 'some-new-device-token'
          }

        @createOtp = @meshbluOtpService
          .post '/v2/passwords'
          .set 'Authorization', "Basic #{newDeviceAuth}"
          .send {
            connector: 'hue-light'
            tag: 'v1.00000'
            githubSlug: 'octoblu/meshblu-connector-hue-light'
            installerVersion: 'v20.00'
            ignitionVersion: 'v02.00'
            octoblu: {}
            meshblu:
              domain: 'some-domain'
          }
          .reply 201, {
            key: 'some-otp-key'
          }

        options =
          uri: '/connectors/some-device-uuid/otp'
          baseUrl: "http://localhost:#{@serverPort}"
          auth:
            username: 'some-device-uuid'
            password: 'some-device-token'
          json: true

        request.post options, (error, @response, @body) =>
          done error

      it 'should return a 201', ->
        expect(@response.statusCode).to.equal 201, JSON.stringify @body

      it 'should return the key', ->
        expect(@body).to.deep.equal { key: 'some-otp-key' }

      it 'should auth the request with meshblu', ->
        @authDevice.done()

      it 'should get the connector device', ->
        @getDevice.done()

      it 'should generate a new token', ->
        @generateToken.done()

      it 'should create the otp', ->
        @createOtp.done()

      it 'should resolve the installer version', ->
        @resolveInstallerVersion.done()

      it 'should resolve the ignition version', ->
        @resolveIgnitionVersion.done()

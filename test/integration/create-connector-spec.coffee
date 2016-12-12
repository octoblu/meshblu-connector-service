shmock        = require 'shmock'
request       = require 'request'
enableDestroy = require 'server-destroy'
Server        = require '../../src/server'

describe 'Create Connector', ->
  beforeEach (done) ->
    @meshblu = shmock 0xd00d
    enableDestroy @meshblu
    @fileDownloadService = shmock 0xbabe
    enableDestroy @fileDownloadService

    @logFn = sinon.spy()
    serverOptions =
      port: null,
      disableLogging: true
      logFn: @logFn
      fileDownloaderUrl: "http://localhost:#{0xbabe}"
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
    @fileDownloadService.destroy()

  describe 'On POST /create', ->
    beforeEach (done) ->
      userAuth = new Buffer('some-uuid:some-token').toString 'base64'

      @authDevice = @meshblu
        .post '/authenticate'
        .set 'Authorization', "Basic #{userAuth}"
        .reply 204

      @getSchemas = @fileDownloadService
        .get '/github-release/some-owner/some-meshblu-connector/v1.0.0/schemas.json'
        .reply 200, {
          schemas: {
            some: 'schema'
          }
        }

      @createDevice = @meshblu
        .post '/devices'
        .set 'Authorization', "Basic #{userAuth}"
        .send {
          name: 'some-name',
          type: 'some-type',
          connector: 'some-meshblu-connector',
          owner: 'some-owner',
          discoverWhitelist: ['some-owner']
          configureWhitelist: ['some-owner']
          sendWhitelist: ['some-owner']
          receiveWhitelist: ['some-owner']
          schemas: {
            some: 'schema'
          }
          connectorMetadata: {
            version: 'v1.0.0',
            githubSlug: 'some-owner/some-meshblu-connector',
            stopped: false
          }
        }
        .reply 201, {
          device: 'response'
          fake: true
        }

      options =
        uri: '/create'
        baseUrl: "http://localhost:#{@serverPort}"
        auth:
          username: 'some-uuid'
          password: 'some-token'
        json:
          name: 'some-name',
          type: 'some-type',
          connector: 'some-meshblu-connector',
          owner: 'some-owner',
          version: 'v1.0.0'
          githubSlug: 'some-owner/some-meshblu-connector'

      request.post options, (error, @response, @body) =>
        done error

    it 'should return a 201', ->
      expect(@response.statusCode).to.equal 201, @body

    it 'should have the device creation response', ->
      expect(@body).to.deep.equal {
        device: 'response'
        fake: true
      }

    it 'should auth the request with meshblu', ->
      @authDevice.done()

    it 'should get the schema', ->
      @getSchemas.done()

    it 'should create the device in meshblu', ->
      @createDevice.done()

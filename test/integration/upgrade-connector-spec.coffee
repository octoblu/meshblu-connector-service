{describe,beforeEach,afterEach,it} = global
{expect}      = require 'chai'
sinon         = require 'sinon'
shmock        = require 'shmock'
request       = require 'request'
enableDestroy = require 'server-destroy'
Server        = require '../../src/server'

describe 'Upgrade Connector', ->
  beforeEach (done) ->
    @meshblu = shmock 0xd00d
    enableDestroy @meshblu
    @fileDownloadService = shmock 0xbabe
    enableDestroy @fileDownloadService
    @githubService = shmock 0xdead
    enableDestroy @githubService

    @logFn = sinon.spy()
    serverOptions =
      port: undefined,
      disableLogging: true
      logFn: @logFn
      fileDownloaderUrl: "http://localhost:#{0xbabe}"
      githubApiUrl: "http://localhost:#{0xdead}"
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
    @fileDownloadService.destroy()
    @githubService.destroy()

  describe 'On PUT /users/some-owner/connectors/:uuid', ->
    describe 'when it does not have a statusDevice', ->
      beforeEach (done) ->
        userAuth = new Buffer('some-uuid:some-token').toString 'base64'

        @authDevice = @meshblu
          .post '/authenticate'
          .set 'Authorization', "Basic #{userAuth}"
          .reply 204

        @resolveVersion = @githubService
          .get '/repos/some-owner/some-meshblu-connector/releases'
          .set 'Authorization', 'token some-github-token'
          .reply 200, [
            { tag_name: 'v2.0.0' }
          ]

        @getDevice = @meshblu
          .get '/v2/devices/some-device-uuid'
          .set 'Authorization', "Basic #{userAuth}"
          .reply 200, {
            uuid: 'some-device-uuid'
            statusDevice: null
          }

        @getSchemas = @fileDownloadService
          .get '/github-release/some-owner/some-meshblu-connector/v2.0.0/schemas.json'
          .reply 200, {
            schemas:
              configure:
                'some-schema':
                  properties:
                    hi:
                      type: 'bool'
          }

        @createStatusDevice = @meshblu
          .post '/devices'
          .set 'Authorization', "Basic #{userAuth}"
          .send {
            type: 'connector-status-device',
            owner: 'some-device-uuid',
            discoverWhitelist: ['some-device-uuid', 'some-owner']
            configureWhitelist: ['some-device-uuid', 'some-owner']
            sendWhitelist: ['some-device-uuid', 'some-owner']
            receiveWhitelist: ['some-device-uuid', 'some-owner']
          }
          .reply 201, {
            uuid: 'some-status-device-uuid'
          }

        @updateDevice = @meshblu
          .patch '/v2/devices/some-device-uuid'
          .set 'Authorization', "Basic #{userAuth}"
          .send {
            type: 'some-type'
            connector: 'some-meshblu-connector'
            statusDevice: 'some-status-device-uuid'
            'connectorMetadata.version': 'v2.0.0',
            'connectorMetadata.githubSlug': 'some-owner/some-meshblu-connector',
            'connectorMetadata.meshblu': { domain: 'some-domain' },
            'octoblu.registryItem': { githubSlug: 'some-owner/some-meshblu-connector' }
            iconUri: 'some-icon-uri'
            schemas:
              configure:
                'some-schema':
                  properties:
                    hi:
                      type: 'bool'
          }
          .reply 204

        options =
          uri: '/users/some-owner/connectors/some-device-uuid'
          baseUrl: "http://localhost:#{@serverPort}"
          auth:
            username: 'some-uuid'
            password: 'some-token'
          json:
            iconUri: 'some-icon-uri'
            type: 'some-type',
            connector: 'some-meshblu-connector',
            version: 'v2.0.0'
            githubSlug: 'some-owner/some-meshblu-connector'
            meshblu:
              domain: 'some-domain'

        request.put options, (error, @response, @body) =>
          done error

      it 'should return a 204', ->
        expect(@response.statusCode).to.equal 204, @body

      it 'should auth the request with meshblu', ->
        @authDevice.done()

      it 'should resolve the version', ->
        @resolveVersion.done()

      it 'should get the schema', ->
        @getSchemas.done()

      it 'should get the device in meshblu', ->
        @getDevice.done()

      it 'should create the status device in meshblu', ->
        @createStatusDevice.done()

      it 'should update the device with the statusDevice uuid', ->
        @updateDevice.done()

    describe 'when it has a statusDevice', ->
      beforeEach (done) ->
        userAuth = new Buffer('some-uuid:some-token').toString 'base64'

        @authDevice = @meshblu
          .post '/authenticate'
          .set 'Authorization', "Basic #{userAuth}"
          .reply 204

        @resolveVersion = @githubService
          .get '/repos/some-owner/some-meshblu-connector/releases/latest'
          .set 'Authorization', 'token some-github-token'
          .reply 200, {
            tag_name: 'v2.5.0'
          }

        @getDevice = @meshblu
          .get '/v2/devices/some-device-uuid'
          .set 'Authorization', "Basic #{userAuth}"
          .reply 200, {
            uuid: 'some-device-uuid'
            statusDevice: 'some-status-device-uuid'
          }

        @getSchemas = @fileDownloadService
          .get '/github-release/some-owner/some-meshblu-connector/v2.5.0/schemas.json'
          .reply 200, {
            schemas: {
              some: 'schema'
            }
          }

        @createStatusDevice = @meshblu
          .post '/devices'
          .set 'Authorization', "Basic #{userAuth}"
          .send {
            type: 'connector-status-device',
            owner: 'some-device-uuid',
            discoverWhitelist: ['some-device-uuid', 'some-owner']
            configureWhitelist: ['some-device-uuid', 'some-owner']
            sendWhitelist: ['some-device-uuid', 'some-owner']
            receiveWhitelist: ['some-device-uuid', 'some-owner']
          }
          .reply 201, {
            uuid: 'some-status-device-uuid'
          }

        @updateDevice = @meshblu
          .patch '/v2/devices/some-device-uuid'
          .set 'Authorization', "Basic #{userAuth}"
          .send {
            name: 'some-name'
            type: 'some-type'
            connector: 'some-meshblu-connector'
            statusDevice: 'some-status-device-uuid'
            'connectorMetadata.version': 'v2.5.0',
            'connectorMetadata.githubSlug': 'some-owner/some-meshblu-connector',
            schemas: {
              some: 'schema'
            },
            'octoblu.registryItem': {
              githubSlug: 'some-owner/some-meshblu-connector'
            }
          }
          .reply 204

        options =
          uri: '/users/some-owner/connectors/some-device-uuid'
          baseUrl: "http://localhost:#{@serverPort}"
          auth:
            username: 'some-uuid'
            password: 'some-token'
          json:
            version: 'latest'
            name: 'some-name',
            type: 'some-type',
            connector: 'some-meshblu-connector',
            githubSlug: 'some-owner/some-meshblu-connector'

        request.put options, (error, @response, @body) =>
          done error

      it 'should return a 204', ->
        expect(@response.statusCode).to.equal 204, @body

      it 'should auth the request with meshblu', ->
        @authDevice.done()

      it 'should get the schema', ->
        @getSchemas.done()

      it 'should get the device in meshblu', ->
        @getDevice.done()

      it 'should get the latest tag', ->
        @resolveVersion.done()

      it 'should not create the status device in meshblu', ->
        expect(@createStatusDevice.isDone).to.be.false

      it 'should update the device with the statusDevice uuid', ->
        @updateDevice.done()

    describe 'when it fails validation', ->
      describe 'when missing the githubSlug', ->
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
              statusDevice: 'some-status-device-uuid'
            }

          options =
            uri: '/users/some-owner/connectors/some-device-uuid'
            baseUrl: "http://localhost:#{@serverPort}"
            auth:
              username: 'some-uuid'
              password: 'some-token'
            json:
              type: '...'
              version: '...'
              name: '...'
              connector: '...'

          request.put options, (error, @response, @body) =>
            done error

        it 'should return a 422', ->
          expect(@response.statusCode).to.equal 422

        it 'should return the error in the body', ->
          expect(@body.error).to.equal 'Upgrade Connector: requires githubSlug in post body'

      describe 'when missing the connector', ->
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
              statusDevice: 'some-status-device-uuid'
            }

          options =
            uri: '/users/some-owner/connectors/some-device-uuid'
            baseUrl: "http://localhost:#{@serverPort}"
            auth:
              username: 'some-uuid'
              password: 'some-token'
            json:
              type: '...'
              githubSlug: '...'
              version: '...'
              name: '...'

          request.put options, (error, @response, @body) =>
            done error

        it 'should return a 422', ->
          expect(@response.statusCode).to.equal 422

        it 'should return the error in the body', ->
          expect(@body.error).to.equal 'Upgrade Connector: requires connector in post body'

      describe 'when missing the type', ->
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
              statusDevice: 'some-status-device-uuid'
            }

          options =
            uri: '/users/some-owner/connectors/some-device-uuid'
            baseUrl: "http://localhost:#{@serverPort}"
            auth:
              username: 'some-uuid'
              password: 'some-token'
            json:
              githubSlug: '...'
              version: '...'
              name: '...'
              connector: '...'

          request.put options, (error, @response, @body) =>
            done error

        it 'should return a 422', ->
          expect(@response.statusCode).to.equal 422

        it 'should return the error in the body', ->
          expect(@body.error).to.equal 'Upgrade Connector: requires type in post body'

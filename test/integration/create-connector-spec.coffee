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

    @connectorDetailService = shmock 0xdead
    enableDestroy @connectorDetailService

    @logFn = sinon.spy()
    serverOptions =
      port: null,
      disableLogging: true
      logFn: @logFn
      fileDownloaderUrl: "http://localhost:#{0xbabe}"
      connectorDetailUrl: "http://localhost:#{0xdead}"
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
    @connectorDetailService.destroy()

  describe 'On POST /users/some-owner/connectors', ->
    describe 'when getting a specific version', ->
      beforeEach (done) ->
        userAuth = new Buffer('some-uuid:some-token').toString 'base64'

        @authDevice = @meshblu
          .post '/authenticate'
          .set 'Authorization', "Basic #{userAuth}"
          .reply 204

        @resolveVersion = @connectorDetailService
          .get '/github/some-owner/some-meshblu-connector'
          .reply 200, {
            tags: {
              'v1.0.0': {}
            }
          }

        @getSchemas = @fileDownloadService
          .get '/github-release/some-owner/some-meshblu-connector/v1.0.0/schemas.json'
          .reply 200, {
            schemas:
              configure:
                'some-schema':
                  properties:
                    hi:
                      type: "bool"
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
            iconUri: 'some-icon-uri'
            schemas:
              configure:
                'some-schema':
                  properties:
                    hi:
                      type: 'bool'
              selected:
                configure: 'some-schema'
            octoblu:
              registryItem:
                githubSlug: 'some-owner/some-meshblu-connector'
            connectorMetadata:
              version: 'v1.0.0',
              githubSlug: 'some-owner/some-meshblu-connector',
              stopped: false
          }
          .reply 201, {
            uuid: 'some-device-uuid'
            device: 'response'
            fake: true
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
          .put '/v2/devices/some-device-uuid'
          .set 'Authorization', "Basic #{userAuth}"
          .send {
            $set:
              statusDevice: 'some-status-device-uuid'
            $addToSet:
              'octoblu.links':
                url: 'https://connector-factory.octoblu.com/connectors/configure/some-device-uuid'
                title: 'View in Connector Factory'
          }
          .reply 204

        @getDeviceFinal = @meshblu
          .get '/v2/devices/some-device-uuid'
          .set 'Authorization', "Basic #{userAuth}"
          .reply 200, {
            uuid: 'some-device-uuid'
            device: 'response'
            fake: true
          }

        options =
          uri: '/users/some-owner/connectors'
          baseUrl: "http://localhost:#{@serverPort}"
          auth:
            username: 'some-uuid'
            password: 'some-token'
          json:
            iconUri: 'some-icon-uri'
            name: 'some-name',
            type: 'some-type',
            connector: 'some-meshblu-connector',
            version: 'v1.0.0'
            githubSlug: 'some-owner/some-meshblu-connector'

        request.post options, (error, @response, @body) =>
          done error

      it 'should auth the request with meshblu', ->
        @authDevice.done()

      it 'should resolve the version', ->
        @resolveVersion.done()

      it 'should get the schema', ->
        @getSchemas.done()

      it 'should create the device in meshblu', ->
        @createDevice.done()

      it 'should create the status device in meshblu', ->
        @createStatusDevice.done()

      it 'should update the device with the statusDevice uuid', ->
        @updateDevice.done()

      it 'should get the device and return it', ->
        @getDeviceFinal.done()

      it 'should return a 201', ->
        expect(@response.statusCode).to.equal 201, @body

      it 'should have the device creation response', ->
        expect(@body).to.deep.equal {
          uuid: 'some-device-uuid'
          device: 'response'
          fake: true
        }

    describe 'when getting the latest', ->
      beforeEach (done) ->
        userAuth = new Buffer('some-uuid:some-token').toString 'base64'

        @authDevice = @meshblu
          .post '/authenticate'
          .set 'Authorization', "Basic #{userAuth}"
          .reply 204

        @resolveVersion = @connectorDetailService
          .get '/github/some-owner/some-meshblu-connector'
          .reply 200, {
            latest: {
              tag: 'v1.5.0'
            }
          }

        @getSchemas = @fileDownloadService
          .get '/github-release/some-owner/some-meshblu-connector/v1.5.0/schemas.json'
          .reply 200, {
            schemas:
              configure:
                'some-schema':
                  properties:
                    hi:
                      type: "bool"
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
            iconUri: 'some-icon-uri'
            schemas:
              configure:
                'some-schema':
                  properties:
                    hi:
                      type: 'bool'
              selected:
                configure: 'some-schema'
            octoblu:
              registryItem:
                githubSlug: 'some-owner/some-meshblu-connector'
            connectorMetadata:
              version: 'v1.5.0',
              githubSlug: 'some-owner/some-meshblu-connector',
              stopped: false
          }
          .reply 201, {
            uuid: 'some-device-uuid'
            device: 'response'
            fake: true
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
          .put '/v2/devices/some-device-uuid'
          .set 'Authorization', "Basic #{userAuth}"
          .send {
            $set:
              statusDevice: 'some-status-device-uuid'
            $addToSet:
              'octoblu.links':
                url: 'https://connector-factory.octoblu.com/connectors/configure/some-device-uuid'
                title: 'View in Connector Factory'
          }
          .reply 204

        @getDeviceFinal = @meshblu
          .get '/v2/devices/some-device-uuid'
          .set 'Authorization', "Basic #{userAuth}"
          .reply 200, {
            uuid: 'some-device-uuid'
            device: 'response'
            fake: true
          }

        options =
          uri: '/users/some-owner/connectors'
          baseUrl: "http://localhost:#{@serverPort}"
          auth:
            username: 'some-uuid'
            password: 'some-token'
          json:
            iconUri: 'some-icon-uri'
            name: 'some-name',
            type: 'some-type',
            connector: 'some-meshblu-connector',
            githubSlug: 'some-owner/some-meshblu-connector'

        request.post options, (error, @response, @body) =>
          done error

      it 'should auth the request with meshblu', ->
        @authDevice.done()

      it 'should get the schema', ->
        @getSchemas.done()

      it 'should create the device in meshblu', ->
        @createDevice.done()

      it 'should create the status device in meshblu', ->
        @createStatusDevice.done()

      it 'should update the device with the statusDevice uuid', ->
        @updateDevice.done()

      it 'should get the device and return it', ->
        @getDeviceFinal.done()

      it 'should call the connector detail service to get the latest', ->
        @resolveVersion.done()

      it 'should return a 201', ->
        expect(@response.statusCode).to.equal 201, @body

      it 'should have the device creation response', ->
        expect(@body).to.deep.equal {
          uuid: 'some-device-uuid'
          device: 'response'
          fake: true
        }

    describe 'when it fails validation', ->
      describe 'when missing the githubSlug', ->
        beforeEach (done) ->
          userAuth = new Buffer('some-uuid:some-token').toString 'base64'

          @authDevice = @meshblu
            .post '/authenticate'
            .set 'Authorization', "Basic #{userAuth}"
            .reply 204

          options =
            uri: '/users/some-owner/connectors'
            baseUrl: "http://localhost:#{@serverPort}"
            auth:
              username: 'some-uuid'
              password: 'some-token'
            json:
              type: '...'
              version: '...'
              name: '...'
              connector: '...'

          request.post options, (error, @response, @body) =>
            done error

        it 'should return a 422', ->
          expect(@response.statusCode).to.equal 422

        it 'should return the error in the body', ->
          expect(@body.error).to.equal 'Create Connector: requires githubSlug in post body'

      describe 'when missing the connector', ->
        beforeEach (done) ->
          userAuth = new Buffer('some-uuid:some-token').toString 'base64'

          @authDevice = @meshblu
            .post '/authenticate'
            .set 'Authorization', "Basic #{userAuth}"
            .reply 204

          options =
            uri: '/users/some-owner/connectors'
            baseUrl: "http://localhost:#{@serverPort}"
            auth:
              username: 'some-uuid'
              password: 'some-token'
            json:
              type: '...'
              githubSlug: '...'
              version: '...'
              name: '...'

          request.post options, (error, @response, @body) =>
            done error

        it 'should return a 422', ->
          expect(@response.statusCode).to.equal 422

        it 'should return the error in the body', ->
          expect(@body.error).to.equal 'Create Connector: requires connector in post body'

      describe 'when missing the type', ->
        beforeEach (done) ->
          userAuth = new Buffer('some-uuid:some-token').toString 'base64'

          @authDevice = @meshblu
            .post '/authenticate'
            .set 'Authorization', "Basic #{userAuth}"
            .reply 204

          options =
            uri: '/users/some-owner/connectors'
            baseUrl: "http://localhost:#{@serverPort}"
            auth:
              username: 'some-uuid'
              password: 'some-token'
            json:
              githubSlug: '...'
              version: '...'
              name: '...'
              connector: '...'

          request.post options, (error, @response, @body) =>
            done error

        it 'should return a 422', ->
          expect(@response.statusCode).to.equal 422

        it 'should return the error in the body', ->
          expect(@body.error).to.equal 'Create Connector: requires type in post body'

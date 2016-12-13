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
    describe 'when succesful', ->
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
          uuid: 'some-device-uuid'
          device: 'response'
          fake: true
        }

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

    describe 'when it fails validation', ->
      describe 'when missing the githubSlug', ->
        beforeEach (done) ->
          userAuth = new Buffer('some-uuid:some-token').toString 'base64'

          @authDevice = @meshblu
            .post '/authenticate'
            .set 'Authorization', "Basic #{userAuth}"
            .reply 204

          options =
            uri: '/create'
            baseUrl: "http://localhost:#{@serverPort}"
            auth:
              username: 'some-uuid'
              password: 'some-token'
            json:
              type: '...'
              owner: '...'
              version: '...'
              name: '...'
              connector: '...'

          request.post options, (error, @response, @body) =>
            done error

        it 'should return a 422', ->
          expect(@response.statusCode).to.equal 422

        it 'should return the error in the body', ->
          expect(@body.error).to.equal 'Create Connector: requires githubSlug in post body'

      describe 'when missing the owner', ->
        beforeEach (done) ->
          userAuth = new Buffer('some-uuid:some-token').toString 'base64'

          @authDevice = @meshblu
            .post '/authenticate'
            .set 'Authorization', "Basic #{userAuth}"
            .reply 204

          options =
            uri: '/create'
            baseUrl: "http://localhost:#{@serverPort}"
            auth:
              username: 'some-uuid'
              password: 'some-token'
            json:
              type: '...'
              githubSlug: '...'
              version: '...'
              name: '...'
              connector: '...'

          request.post options, (error, @response, @body) =>
            done error

        it 'should return a 422', ->
          expect(@response.statusCode).to.equal 422

        it 'should return the error in the body', ->
          expect(@body.error).to.equal 'Create Connector: requires owner in post body'

      describe 'when missing the version', ->
        beforeEach (done) ->
          userAuth = new Buffer('some-uuid:some-token').toString 'base64'

          @authDevice = @meshblu
            .post '/authenticate'
            .set 'Authorization', "Basic #{userAuth}"
            .reply 204

          options =
            uri: '/create'
            baseUrl: "http://localhost:#{@serverPort}"
            auth:
              username: 'some-uuid'
              password: 'some-token'
            json:
              type: '...'
              githubSlug: '...'
              owner: '...'
              name: '...'
              connector: '...'

          request.post options, (error, @response, @body) =>
            done error

        it 'should return a 422', ->
          expect(@response.statusCode).to.equal 422

        it 'should return the error in the body', ->
          expect(@body.error).to.equal 'Create Connector: requires version in post body'

      describe 'when missing the name', ->
        beforeEach (done) ->
          userAuth = new Buffer('some-uuid:some-token').toString 'base64'

          @authDevice = @meshblu
            .post '/authenticate'
            .set 'Authorization', "Basic #{userAuth}"
            .reply 204

          options =
            uri: '/create'
            baseUrl: "http://localhost:#{@serverPort}"
            auth:
              username: 'some-uuid'
              password: 'some-token'
            json:
              type: '...'
              githubSlug: '...'
              owner: '...'
              version: '...'
              connector: '...'

          request.post options, (error, @response, @body) =>
            done error

        it 'should return a 422', ->
          expect(@response.statusCode).to.equal 422

        it 'should return the error in the body', ->
          expect(@body.error).to.equal 'Create Connector: requires name in post body'

      describe 'when missing the connector', ->
        beforeEach (done) ->
          userAuth = new Buffer('some-uuid:some-token').toString 'base64'

          @authDevice = @meshblu
            .post '/authenticate'
            .set 'Authorization', "Basic #{userAuth}"
            .reply 204

          options =
            uri: '/create'
            baseUrl: "http://localhost:#{@serverPort}"
            auth:
              username: 'some-uuid'
              password: 'some-token'
            json:
              type: '...'
              githubSlug: '...'
              owner: '...'
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
            uri: '/create'
            baseUrl: "http://localhost:#{@serverPort}"
            auth:
              username: 'some-uuid'
              password: 'some-token'
            json:
              githubSlug: '...'
              owner: '...'
              version: '...'
              name: '...'
              connector: '...'

          request.post options, (error, @response, @body) =>
            done error

        it 'should return a 422', ->
          expect(@response.statusCode).to.equal 422

        it 'should return the error in the body', ->
          expect(@body.error).to.equal 'Create Connector: requires type in post body'

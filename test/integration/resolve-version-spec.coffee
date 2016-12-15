shmock         = require 'shmock'
request        = require 'request'
enableDestroy  = require 'server-destroy'
{ someSchema } = require './assets/example-schemas.json'
Server         = require '../../src/server'

describe 'Resolve Version', ->
  beforeEach (done) ->
    @meshblu = shmock 0xd00d
    enableDestroy @meshblu

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
    @connectorDetailService.destroy()

  describe 'On GET /releases/:owner/:repo/:tag/version/resolve', ->
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
            tags: 'v1.0.0': {}
          }

        options =
          uri: '/releases/some-owner/some-meshblu-connector/v1.0.0/version/resolve'
          baseUrl: "http://localhost:#{@serverPort}"
          auth:
            username: 'some-uuid'
            password: 'some-token'
          json: true

        request.get options, (error, @response, @body) =>
          done error

      it 'should auth the request with meshblu', ->
        @authDevice.done()

      it 'should resolve the version', ->
        @resolveVersion.done()

      it 'should return a 200', ->
        expect(@response.statusCode).to.equal 200, @body

      it 'should have the schemas in the response', ->
        expect(@body).to.deep.equal { version: 'v1.0.0' }

    describe 'when getting latest', ->
      beforeEach (done) ->
        userAuth = new Buffer('some-uuid:some-token').toString 'base64'

        @authDevice = @meshblu
          .post '/authenticate'
          .set 'Authorization', "Basic #{userAuth}"
          .reply 204

        @resolveVersion = @connectorDetailService
          .get '/github/some-owner/some-meshblu-connector'
          .reply 200, {
            latest:
              tag: 'v2.0.0'
          }

        options =
          uri: '/releases/some-owner/some-meshblu-connector/latest/version/resolve'
          baseUrl: "http://localhost:#{@serverPort}"
          auth:
            username: 'some-uuid'
            password: 'some-token'
          json: true

        request.get options, (error, @response, @body) =>
          done error

      it 'should auth the request with meshblu', ->
        @authDevice.done()

      it 'should resolve the version', ->
        @resolveVersion.done()

      it 'should return a 200', ->
        expect(@response.statusCode).to.equal 200, @body

      it 'should have the schemas in the response', ->
        expect(@body).to.deep.equal { version: 'v2.0.0' }

    describe 'when the version does not exist', ->
      beforeEach (done) ->
        userAuth = new Buffer('some-uuid:some-token').toString 'base64'

        @authDevice = @meshblu
          .post '/authenticate'
          .set 'Authorization', "Basic #{userAuth}"
          .reply 204

        @resolveVersion = @connectorDetailService
          .get '/github/some-owner/some-meshblu-connector'
          .reply 200, {
            tags: 'v1.0.0': {}
          }

        options =
          uri: '/releases/some-owner/some-meshblu-connector/v13.13.13/version/resolve'
          baseUrl: "http://localhost:#{@serverPort}"
          auth:
            username: 'some-uuid'
            password: 'some-token'
          json: true

        request.get options, (error, @response, @body) =>
          done error

      it 'should auth the request with meshblu', ->
        @authDevice.done()

      it 'should resolve the version', ->
        @resolveVersion.done()

      it 'should return a 404', ->
        expect(@response.statusCode).to.equal 404, @body

    describe 'when the version is a prerelease', ->
      beforeEach (done) ->
        userAuth = new Buffer('some-uuid:some-token').toString 'base64'

        @authDevice = @meshblu
          .post '/authenticate'
          .set 'Authorization', "Basic #{userAuth}"
          .reply 204

        @resolveVersion = @connectorDetailService
          .get '/github/some-owner/some-meshblu-connector'
          .reply 200, {
            tags: 'v1.0.0': {prerelease: true}
          }

        options =
          uri: '/releases/some-owner/some-meshblu-connector/v1.0.0/version/resolve'
          baseUrl: "http://localhost:#{@serverPort}"
          auth:
            username: 'some-uuid'
            password: 'some-token'
          json: true

        request.get options, (error, @response, @body) =>
          done error

      it 'should auth the request with meshblu', ->
        @authDevice.done()

      it 'should resolve the version', ->
        @resolveVersion.done()

      it 'should return a 406', ->
        expect(@response.statusCode).to.equal 406, @body

      it 'should have the error in the response', ->
        expect(@body).to.deep.equal {error: 'v1.0.0 (prerelease) is invalid'}

    describe 'when the version is a draft', ->
      beforeEach (done) ->
        userAuth = new Buffer('some-uuid:some-token').toString 'base64'

        @authDevice = @meshblu
          .post '/authenticate'
          .set 'Authorization', "Basic #{userAuth}"
          .reply 204

        @resolveVersion = @connectorDetailService
          .get '/github/some-owner/some-meshblu-connector'
          .reply 200, {
            tags: 'v1.0.0': {draft: true}
          }

        options =
          uri: '/releases/some-owner/some-meshblu-connector/v1.0.0/version/resolve'
          baseUrl: "http://localhost:#{@serverPort}"
          auth:
            username: 'some-uuid'
            password: 'some-token'
          json: true

        request.get options, (error, @response, @body) =>
          done error

      it 'should auth the request with meshblu', ->
        @authDevice.done()

      it 'should resolve the version', ->
        @resolveVersion.done()

      it 'should return a 406', ->
        expect(@response.statusCode).to.equal 406, @body

      it 'should have the error in the response', ->
        expect(@body).to.deep.equal {error: 'v1.0.0 (draft) is invalid'}

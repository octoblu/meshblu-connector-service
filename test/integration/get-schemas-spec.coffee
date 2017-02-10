{describe,beforeEach,afterEach,it} = global
{expect}      = require 'chai'
sinon         = require 'sinon'
shmock         = require 'shmock'
request        = require 'request'
enableDestroy  = require 'server-destroy'
{ someSchema } = require './assets/example-schemas.json'
Server         = require '../../src/server'

describe 'Get Schemas', ->
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

  describe 'On GET /releases/:owner/:repo/:tag/schemas', ->
    describe 'when getting a specific version', ->
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
            { tag_name: 'v1.0.0' }
          ]

        @getSchemas = @fileDownloadService
          .get '/github-release/some-owner/some-meshblu-connector/v1.0.0/schemas.json'
          .reply 200, someSchema

        options =
          uri: '/releases/some-owner/some-meshblu-connector/v1.0.0/schemas'
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

      it 'should get the schema', ->
        @getSchemas.done()

      it 'should return a 200', ->
        expect(@response.statusCode).to.equal 200, @body

      it 'should have the schemas in the response', ->
        expect(@body).to.deep.equal someSchema.schemas

    describe 'when getting latest', ->
      beforeEach (done) ->
        userAuth = new Buffer('some-uuid:some-token').toString 'base64'

        @authDevice = @meshblu
          .post '/authenticate'
          .set 'Authorization', "Basic #{userAuth}"
          .reply 204

        @resolveVersion = @githubService
          .get "/repos/some-owner/some-meshblu-connector/releases/latest"
          .set 'Authorization', 'token some-github-token'
          .reply 200, {
            tag_name: 'v1.5.0'
          }

        @getSchemas = @fileDownloadService
          .get '/github-release/some-owner/some-meshblu-connector/v1.5.0/schemas.json'
          .reply 200, someSchema

        options =
          uri: '/releases/some-owner/some-meshblu-connector/latest/schemas'
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

      it 'should get the schema', ->
        @getSchemas.done()

      it 'should return a 200', ->
        expect(@response.statusCode).to.equal 200, @body

      it 'should have the schemas in the response', ->
        expect(@body).to.deep.equal someSchema.schemas

    describe 'when the schema is not found', ->
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
            { tag_name: 'v13.13.13' }
          ]

        @getSchemas = @fileDownloadService
          .get '/github-release/some-owner/some-meshblu-connector/v13.13.13/schemas.json'
          .reply 404

        options =
          uri: '/releases/some-owner/some-meshblu-connector/v13.13.13/schemas'
          baseUrl: "http://localhost:#{@serverPort}"
          auth:
            username: 'some-uuid'
            password: 'some-token'
          json: true

        request.get options, (error, @response, @body) =>
          done error

      it 'should auth the request with meshblu', ->
        @authDevice.done()

      it 'should get the schema', ->
        @getSchemas.done()

      it 'should return a 404', ->
        expect(@response.statusCode).to.equal 404, @body

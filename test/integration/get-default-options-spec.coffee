shmock        = require 'shmock'
request       = require 'request'
enableDestroy = require 'server-destroy'
Server        = require '../../src/server'
{
  someSchema
  defaultSchema
  DefaultSchema
  noDefaultSchema
  skypeSchema
  hueLightSchema
} = require './assets/example-schemas.json'

describe 'Get Default Options', ->
  beforeEach (done) ->
    @meshblu = shmock 0xd00d
    enableDestroy @meshblu

    @logFn = sinon.spy()
    serverOptions =
      port: null,
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

  describe 'On POST /schemas/default-options', ->
    describe 'when there is only one configure schema', ->
      beforeEach (done) ->
        userAuth = new Buffer('some-uuid:some-token').toString 'base64'

        @authDevice = @meshblu
          .post '/authenticate'
          .set 'Authorization', "Basic #{userAuth}"
          .reply 204

        options =
          uri: '/schemas/default-options'
          baseUrl: "http://localhost:#{@serverPort}"
          auth:
            username: 'some-uuid'
            password: 'some-token'
          json: someSchema

        request.post options, (error, @response, @body) =>
          done error

      it 'should auth the request with meshblu', ->
        @authDevice.done()

      it 'should return a 200', ->
        expect(@response.statusCode).to.equal 200, @body

      it 'should have the default-options in the response', ->
        expect(@body).to.deep.equal {
          options:
            greeting: 'Howdy'
          schemas:
            selected:
              configure: 'SomeSchema'
        }

    describe 'when there are multiple schemas', ->
      describe 'when there is a "default" schema', ->
        beforeEach (done) ->
          userAuth = new Buffer('some-uuid:some-token').toString 'base64'

          @authDevice = @meshblu
            .post '/authenticate'
            .set 'Authorization', "Basic #{userAuth}"
            .reply 204

          options =
            uri: '/schemas/default-options'
            baseUrl: "http://localhost:#{@serverPort}"
            auth:
              username: 'some-uuid'
              password: 'some-token'
            json: defaultSchema

          request.post options, (error, @response, @body) =>
            done error

        it 'should auth the request with meshblu', ->
          @authDevice.done()

        it 'should return a 200', ->
          expect(@response.statusCode).to.equal 200, @body

        it 'should have the default-options in the response', ->
          expect(@body).to.deep.equal {
            options:
              type: 'is-default'
            schemas:
              selected:
                configure: 'default'
          }

      describe 'when there is a "Default" schema', ->
        beforeEach (done) ->
          userAuth = new Buffer('some-uuid:some-token').toString 'base64'

          @authDevice = @meshblu
            .post '/authenticate'
            .set 'Authorization', "Basic #{userAuth}"
            .reply 204

          options =
            uri: '/schemas/default-options'
            baseUrl: "http://localhost:#{@serverPort}"
            auth:
              username: 'some-uuid'
              password: 'some-token'
            json: DefaultSchema

          request.post options, (error, @response, @body) =>
            done error

        it 'should auth the request with meshblu', ->
          @authDevice.done()

        it 'should return a 200', ->
          expect(@response.statusCode).to.equal 200, @body

        it 'should have the default-options in the response', ->
          expect(@body).to.deep.equal {
            options:
              color: 'blueish-green-yellow-maybe'
            schemas:
              selected:
                configure: 'Default'
          }

    describe 'when using the skype schema', ->
      beforeEach (done) ->
        userAuth = new Buffer('some-uuid:some-token').toString 'base64'

        @authDevice = @meshblu
          .post '/authenticate'
          .set 'Authorization', "Basic #{userAuth}"
          .reply 204

        options =
          uri: '/schemas/default-options'
          baseUrl: "http://localhost:#{@serverPort}"
          auth:
            username: 'some-uuid'
            password: 'some-token'
          json: skypeSchema

        request.post options, (error, @response, @body) =>
          done error

      it 'should auth the request with meshblu', ->
        @authDevice.done()

      it 'should return a 200', ->
        expect(@response.statusCode).to.equal 200, @body

      it 'should have the default-options in the response', ->
        expect(@body).to.deep.equal {
          desiredState:
            audioEnabled: false
            meeting: {}
            videoEnabled: false
          schemas:
            selected:
              configure: 'Default'
        }

    describe 'when using the hue-light schema', ->
      beforeEach (done) ->
        userAuth = new Buffer('some-uuid:some-token').toString 'base64'

        @authDevice = @meshblu
          .post '/authenticate'
          .set 'Authorization', "Basic #{userAuth}"
          .reply 204

        options =
          uri: '/schemas/default-options'
          baseUrl: "http://localhost:#{@serverPort}"
          auth:
            username: 'some-uuid'
            password: 'some-token'
          json: hueLightSchema

        request.post options, (error, @response, @body) =>
          done error

      it 'should auth the request with meshblu', ->
        @authDevice.done()

      it 'should return a 200', ->
        expect(@response.statusCode).to.equal 200, @body

      it 'should have the default-options in the response', ->
        expect(@body).to.deep.equal {
          desiredState: {}
          options:
            lightNumber: 0
          schemas:
            selected:
              configure: 'Default'
        }

    describe 'when there is no default schema', ->
      beforeEach (done) ->
        userAuth = new Buffer('some-uuid:some-token').toString 'base64'

        @authDevice = @meshblu
          .post '/authenticate'
          .set 'Authorization', "Basic #{userAuth}"
          .reply 204

        options =
          uri: '/schemas/default-options'
          baseUrl: "http://localhost:#{@serverPort}"
          auth:
            username: 'some-uuid'
            password: 'some-token'
          json: noDefaultSchema

        request.post options, (error, @response, @body) =>
          done error

      it 'should auth the request with meshblu', ->
        @authDevice.done()

      it 'should return a 200', ->
        expect(@response.statusCode).to.equal 200, @body

      it 'should have no default-options in the response', ->
        expect(@body).to.not.exist

    describe 'when no schemas are sent in the body', ->
      beforeEach (done) ->
        userAuth = new Buffer('some-uuid:some-token').toString 'base64'

        @authDevice = @meshblu
          .post '/authenticate'
          .set 'Authorization', "Basic #{userAuth}"
          .reply 204

        options =
          uri: '/schemas/default-options'
          baseUrl: "http://localhost:#{@serverPort}"
          auth:
            username: 'some-uuid'
            password: 'some-token'
          json: true

        request.post options, (error, @response, @body) =>
          done error

      it 'should auth the request with meshblu', ->
        @authDevice.done()

      it 'should return a 422', ->
        expect(@response.statusCode).to.equal 422, @body

      it 'should have the default-options in the response', ->
        expect(@body).to.deep.equal { error: 'Method requires schemas in body' }

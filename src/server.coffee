enableDestroy           = require 'server-destroy'
octobluExpress          = require 'express-octoblu'
MeshbluAuth             = require 'express-meshblu-auth'
Router                  = require './router'
SchemaService           = require './services/schema-service'
MeshbluConnectorService = require './services/meshblu-connector-service'
debug                   = require('debug')('meshblu-connector-service:server')

class Server
  constructor: ({@logFn, @disableLogging, @port, @meshbluConfig, @fileDownloaderUrl})->
    throw new Error 'Server: requires meshbluConfig' unless @meshbluConfig?
    throw new Error 'Server: requries fileDownloaderUrl' unless @fileDownloaderUrl?

  address: =>
    @server.address()

  run: (callback) =>
    app = octobluExpress({ @logFn, @disableLogging })

    meshbluAuth = new MeshbluAuth @meshbluConfig
    app.use meshbluAuth.auth()
    app.use meshbluAuth.gateway()

    schemaService = new SchemaService { @fileDownloaderUrl }
    meshbluConnectorService = new MeshbluConnectorService {schemaService}
    router = new Router {@meshbluConfig, meshbluConnectorService}

    router.route app

    @server = app.listen @port, callback
    enableDestroy @server

  stop: (callback) =>
    @server.close callback

  destroy: =>
    @server.destroy()

module.exports = Server

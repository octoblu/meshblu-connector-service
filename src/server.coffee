enableDestroy           = require 'server-destroy'
octobluExpress          = require 'express-octoblu'
MeshbluAuth             = require 'express-meshblu-auth'
Router                  = require './router'
SchemaService           = require './services/schema-service'
CreateConnectorService  = require './services/create-connector-service'
UpgradeConnectorService = require './services/upgrade-connector-service'
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
    upgradeConnectorService = new UpgradeConnectorService { schemaService }
    createConnectorService = new CreateConnectorService { schemaService }
    router = new Router {@meshbluConfig,upgradeConnectorService,createConnectorService}

    router.route app

    @server = app.listen @port, callback
    enableDestroy @server

  stop: (callback) =>
    @server.close callback

  destroy: =>
    @server.destroy()

module.exports = Server

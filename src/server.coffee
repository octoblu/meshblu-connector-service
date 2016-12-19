enableDestroy           = require 'server-destroy'
octobluExpress          = require 'express-octoblu'
MeshbluAuth             = require 'express-meshblu-auth'
Router                  = require './router'
SchemaService           = require './services/schema-service'
ConnectorDetailService  = require './services/connector-detail-service'
CreateConnectorService  = require './services/create-connector-service'
UpgradeConnectorService = require './services/upgrade-connector-service'
debug                   = require('debug')('meshblu-connector-service:server')

class Server
  constructor: ({@logFn,@disableLogging,@port,@meshbluConfig,@fileDownloaderUrl,@githubToken,@githubApiUrl})->
    throw new Error 'Server: requires meshbluConfig' unless @meshbluConfig?
    throw new Error 'Server: requires fileDownloaderUrl' unless @fileDownloaderUrl?
    throw new Error 'Server: requires githubToken' unless @githubToken?
    throw new Error 'Server: requires githubApiUrl' unless @githubApiUrl?

  address: =>
    @server.address()

  run: (callback) =>
    app = octobluExpress({ @logFn, @disableLogging })

    meshbluAuth = new MeshbluAuth @meshbluConfig
    app.use meshbluAuth.auth()
    app.use meshbluAuth.gateway()

    connectorDetailService = new ConnectorDetailService { @githubToken, @githubApiUrl }
    schemaService = new SchemaService { @fileDownloaderUrl, connectorDetailService }
    upgradeConnectorService = new UpgradeConnectorService { schemaService, connectorDetailService }
    createConnectorService = new CreateConnectorService { schemaService, connectorDetailService }
    router = new Router {
      @meshbluConfig,
      upgradeConnectorService,
      createConnectorService,
      schemaService,
      connectorDetailService,
    }

    router.route app

    @server = app.listen @port, callback
    enableDestroy @server

  stop: (callback) =>
    @server.close callback

  destroy: =>
    @server.destroy()

module.exports = Server

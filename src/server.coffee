enableDestroy           = require 'server-destroy'
octobluExpress          = require 'express-octoblu'
MeshbluAuth             = require 'express-meshblu-auth'
Router                  = require './router'
{
  ConnectorDetailService
  CreateConnectorService
  SchemaService
  UpgradeConnectorService
  OtpService
}  = require './services'

class Server
  constructor: (options) ->
    {@logFn,@disableLogging,@port,@meshbluConfig} = options
    {@fileDownloaderUrl,@githubToken,@githubApiUrl} = options
    {@meshbluOtpUrl} = options
    throw new Error 'Server: requires meshbluConfig' unless @meshbluConfig?
    throw new Error 'Server: requires fileDownloaderUrl' unless @fileDownloaderUrl?
    throw new Error 'Server: requires githubToken' unless @githubToken?
    throw new Error 'Server: requires githubApiUrl' unless @githubApiUrl?
    throw new Error 'Server: requires meshbluOtpUrl' unless @meshbluOtpUrl?

  address: =>
    @server.address()

  run: (callback) =>
    app = octobluExpress({ @logFn, @disableLogging })

    meshbluAuth = new MeshbluAuth @meshbluConfig
    app.use meshbluAuth.auth()

    connectorDetailService = new ConnectorDetailService { @githubToken, @githubApiUrl }
    schemaService = new SchemaService { @fileDownloaderUrl, connectorDetailService }
    upgradeConnectorService = new UpgradeConnectorService { schemaService, connectorDetailService }
    createConnectorService = new CreateConnectorService { schemaService, connectorDetailService }
    otpService = new OtpService { @meshbluOtpUrl, connectorDetailService }
    router = new Router {
      @meshbluConfig
      upgradeConnectorService
      createConnectorService
      schemaService
      connectorDetailService
      otpService
    }

    router.route app

    @server = app.listen @port, callback
    enableDestroy @server

  stop: (callback) =>
    @server.close callback

  destroy: =>
    @server.destroy()

module.exports = Server

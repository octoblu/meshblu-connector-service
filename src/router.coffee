MeshbluConnectorController = require './controllers/meshblu-connector-controller'

class Router
  constructor: (options) ->
    {@createConnectorService,@upgradeConnectorService} = options
    {@schemaService,@connectorDetailService} = options
    {@otpService} = options
    throw new Error 'Router: requires createConnectorService' unless @createConnectorService?
    throw new Error 'Router: requires upgradeConnectorService' unless @upgradeConnectorService?
    throw new Error 'Router: requires connectorDetailService' unless @connectorDetailService?
    throw new Error 'Router: requires schemaService' unless @schemaService?
    throw new Error 'Router: requires otpService' unless @otpService?

  route: (app) =>
    meshbluConnectorController = new MeshbluConnectorController {
      @createConnectorService,
      @upgradeConnectorService,
      @schemaService,
      @connectorDetailService,
      @otpService,
    }

    app.post '/users/:owner/connectors', meshbluConnectorController.create
    app.put '/users/:owner/connectors/:uuid', meshbluConnectorController.upgrade
    app.get '/releases/:owner/:repo/:version/schemas', meshbluConnectorController.getSchemas
    app.get '/releases/:owner/:repo/:version/version/resolve', meshbluConnectorController.resolveVersion
    app.post '/schemas/default-options', meshbluConnectorController.getDefaultOptions
    app.post '/connectors/:uuid/otp', meshbluConnectorController.generateOTP

module.exports = Router

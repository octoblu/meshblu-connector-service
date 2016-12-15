MeshbluConnectorController = require './controllers/meshblu-connector-controller'

class Router
  constructor: ({@createConnectorService,@upgradeConnectorService,@schemaService,@connectorDetailService}) ->
    throw new Error 'Router: requires createConnectorService' unless @createConnectorService?
    throw new Error 'Router: requires upgradeConnectorService' unless @upgradeConnectorService?
    throw new Error 'Router: requires connectorDetailService' unless @connectorDetailService?
    throw new Error 'Router: requires schemaService' unless @schemaService?

  route: (app) =>
    meshbluConnectorController = new MeshbluConnectorController {
      @createConnectorService,
      @upgradeConnectorService,
      @schemaService,
      @connectorDetailService,
    }

    app.post '/users/:owner/connectors', meshbluConnectorController.create
    app.put '/users/:owner/connectors/:uuid', meshbluConnectorController.upgrade
    app.get '/releases/:owner/:repo/:version/schemas', meshbluConnectorController.getSchemas
    app.get '/releases/:owner/:repo/:version/version/resolve', meshbluConnectorController.resolveVersion
    app.post '/schemas/default-options', meshbluConnectorController.getDefaultOptions

module.exports = Router

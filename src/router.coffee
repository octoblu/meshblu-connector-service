MeshbluConnectorController = require './controllers/meshblu-connector-controller'

class Router
  constructor: ({@createConnectorService,@upgradeConnectorService,@schemaService}) ->
    throw new Error 'Router: requires createConnectorService' unless @createConnectorService?
    throw new Error 'Router: requires upgradeConnectorService' unless @upgradeConnectorService?
    throw new Error 'Router: requires schemaService' unless @schemaService?

  route: (app) =>
    meshbluConnectorController = new MeshbluConnectorController {
      @createConnectorService,
      @upgradeConnectorService,
      @schemaService,
    }

    app.post '/users/:owner/connectors', meshbluConnectorController.create
    app.put '/users/:owner/connectors/:uuid', meshbluConnectorController.upgrade
    app.get '/connectors/:owner/:connector/:version/schemas', meshbluConnectorController.getSchemas

module.exports = Router

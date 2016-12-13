MeshbluConnectorController = require './controllers/meshblu-connector-controller'

class Router
  constructor: ({@createConnectorService,@upgradeConnectorService}) ->
    throw new Error 'Router: requires createConnectorService' unless @createConnectorService?
    throw new Error 'Router: requires upgradeConnectorService' unless @upgradeConnectorService?

  route: (app) =>
    meshbluConnectorController = new MeshbluConnectorController {@createConnectorService,@upgradeConnectorService}

    app.post '/users/:owner/connectors', meshbluConnectorController.create
    app.put '/users/:owner/connectors/:uuid', meshbluConnectorController.upgrade

module.exports = Router

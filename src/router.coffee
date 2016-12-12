MeshbluConnectorController = require './controllers/meshblu-connector-controller'

class Router
  constructor: ({@meshbluConnectorService}) ->
    throw new Error 'Router: requires meshbluConnectorService' unless @meshbluConnectorService?

  route: (app) =>
    meshbluConnectorController = new MeshbluConnectorController {@meshbluConnectorService}

    app.post '/create', meshbluConnectorController.create

module.exports = Router

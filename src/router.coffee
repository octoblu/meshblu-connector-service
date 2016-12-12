MeshbluConnectorController = require './controllers/meshblu-connector-controller'

class Router
  constructor: ({@meshbluConnectorService}) ->
    throw new Error 'Missing meshbluConnectorService' unless @meshbluConnectorService?

  route: (app) =>
    meshbluConnectorController = new MeshbluConnectorController {@meshbluConnectorService}

    app.post '/create', meshbluConnectorController.create
    # e.g. app.put '/resource/:id', someController.update

module.exports = Router

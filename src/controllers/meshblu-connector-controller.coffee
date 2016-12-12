class MeshbluConnectorController
  constructor: ({@meshbluConnectorService}) ->
    throw new Error 'MeshbluConnectorController: requires meshbluConnectorService' unless @meshbluConnectorService?

  create: (request, response) =>
    { meshbluAuth, body } = request
    @meshbluConnectorService.create { body, meshbluAuth }, (error, device) =>
      console.error error if error?
      return response.sendError(error) if error?
      response.status(201).send(device)

module.exports = MeshbluConnectorController

class MeshbluConnectorController
  constructor: ({@meshbluConnectorService}) ->
    throw new Error 'Missing meshbluConnectorService' unless @meshbluConnectorService?

  create: (request, response) =>
    @meshbluConnectorService.create {}, (error) =>
      return response.sendError(error) if error?
      response.sendStatus(201)

module.exports = MeshbluConnectorController

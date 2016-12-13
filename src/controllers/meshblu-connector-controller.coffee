class MeshbluConnectorController
  constructor: ({@createConnectorService,@upgradeConnectorService}) ->
    throw new Error 'MeshbluConnectorController: requires createConnectorService' unless @createConnectorService?
    throw new Error 'MeshbluConnectorController: requires upgradeConnectorService' unless @upgradeConnectorService?

  create: (request, response) =>
    { meshbluAuth, body } = request
    @createConnectorService.do { body, meshbluAuth }, (error, device) =>
      console.error(error) if error?.code >= 500
      return response.sendError(error) if error?
      response.status(201).send(device)

  upgrade: (request, response) =>
    { meshbluAuth, body } = request
    { uuid } = request.params
    @upgradeConnectorService.do { body, meshbluAuth, uuid }, (error, device) =>
      console.error(error) if error?.code >= 500
      return response.sendError(error) if error?
      response.sendStatus(204)

module.exports = MeshbluConnectorController

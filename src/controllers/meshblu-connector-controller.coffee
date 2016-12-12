class MeshbluConnectorController
  constructor: ({@meshbluConnectorService}) ->
    throw new Error 'MeshbluConnectorController: requires meshbluConnectorService' unless @meshbluConnectorService?

  create: (request, response) =>
    { name, connector, type, githubSlug, version, owner } = request.body
    { meshbluAuth } = request
    @meshbluConnectorService.create { name, connector, type, githubSlug, version, owner, meshbluAuth }, (error) =>
      return response.sendError(error) if error?
      response.sendStatus(201)

module.exports = MeshbluConnectorController

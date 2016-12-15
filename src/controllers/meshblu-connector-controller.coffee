_ = require 'lodash'

class MeshbluConnectorController
  constructor: ({@createConnectorService,@upgradeConnectorService,@schemaService,@connectorDetailService}) ->
    throw new Error 'MeshbluConnectorController: requires createConnectorService' unless @createConnectorService?
    throw new Error 'MeshbluConnectorController: requires upgradeConnectorService' unless @upgradeConnectorService?
    throw new Error 'MeshbluConnectorController: requires connectorDetailService' unless @connectorDetailService?
    throw new Error 'MeshbluConnectorController: requires schemaService' unless @schemaService?

  create: (request, response) =>
    { owner } = request.params
    { meshbluAuth, body } = request
    @createConnectorService.do { body, meshbluAuth, owner }, (error, device) =>
      console.error('Create Connector Error', error) if error?.code >= 500
      return response.sendError(error) if error?
      response.status(201).send(device)

  upgrade: (request, response) =>
    { meshbluAuth, body } = request
    { owner, uuid } = request.params
    @upgradeConnectorService.do { body, meshbluAuth, uuid, owner }, (error, device) =>
      console.error('Upgrade Connector Error', error) if error?.code >= 500
      return response.sendError(error) if error?
      response.sendStatus(204)

  getSchemas: (request, response) =>
    { owner, repo, version } = request.params
    githubSlug = "#{owner}/#{repo}"
    @connectorDetailService.resolveVersion { githubSlug, version }, (error, version) =>
      return response.sendError(error) if error?
      @schemaService.get { githubSlug, version }, (error, schemas) =>
        console.error('Get Schemas Error', error) if error?.code >= 500
        return response.sendError(error) if error?
        response.status(200).send(schemas)

  getDefaultOptions: (request, response) =>
    { schemas } = request.body
    return response.status(422).send { error: 'Method requires schemas in body' } if _.isEmpty schemas
    defaultOptions = @schemaService.defaultOptions { schemas }
    response.status(200).send defaultOptions

  resolveVersion: (request, response) =>
    { owner, repo, version } = request.params
    githubSlug = "#{owner}/#{repo}"
    @connectorDetailService.resolveVersion { githubSlug, version }, (error, version) =>
      console.error('Resolve Version Error', error) if error?.code >= 500
      return response.sendError(error) if error?
      response.status(200).send({ version })

module.exports = MeshbluConnectorController

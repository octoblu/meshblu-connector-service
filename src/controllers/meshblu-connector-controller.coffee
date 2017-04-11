_ = require 'lodash'

class MeshbluConnectorController
  constructor: (options) ->
    {@createConnectorService,@upgradeConnectorService} = options
    {@schemaService,@connectorDetailService} = options
    {@otpService} = options
    throw new Error 'MeshbluConnectorController: requires createConnectorService' unless @createConnectorService?
    throw new Error 'MeshbluConnectorController: requires upgradeConnectorService' unless @upgradeConnectorService?
    throw new Error 'MeshbluConnectorController: requires connectorDetailService' unless @connectorDetailService?
    throw new Error 'MeshbluConnectorController: requires schemaService' unless @schemaService?
    throw new Error 'MeshbluConnectorController: requires otpService' unless @otpService?

  create: (request, response) =>
    { owner } = request.params
    { meshbluAuth, body } = request
    return response.status(403).send({ error: 'Forbidden' }) unless meshbluAuth?
    @createConnectorService.do { body, meshbluAuth, owner }, (error, device) =>
      return response.sendError(error) if error?
      response.status(201).send(device)

  getSchemas: (request, response) =>
    { owner, repo, version } = request.params
    githubSlug = "#{owner}/#{repo}"
    @connectorDetailService.resolveVersion { githubSlug, version }, (error, version) =>
      return response.sendError(error) if error?
      @schemaService.get { githubSlug, version }, (error, schemas) =>
        return response.sendError(error) if error?
        response.status(200).send(schemas)

  getDefaultOptions: (request, response) =>
    { schemas } = request.body
    return response.status(422).send { error: 'Method requires schemas in body' } if _.isEmpty schemas
    defaultOptions = @schemaService.defaultOptions { schemas }
    response.status(200).send defaultOptions

  generateOtp: (request, response) =>
    { meshbluAuth } = request
    { uuid } = request.params
    return response.status(403).send({ error: 'Forbidden' }) unless meshbluAuth?
    @otpService.generate { uuid, meshbluAuth }, (error, result) =>
      return response.sendError(error) if error?
      response.status(201).send(result)

  resolveVersion: (request, response) =>
    { owner, repo, version } = request.params
    githubSlug = "#{owner}/#{repo}"
    @connectorDetailService.resolveVersion { githubSlug, version }, (error, version) =>
      return response.sendError(error) if error?
      response.status(200).send({ version })

  upgrade: (request, response) =>
    { meshbluAuth, body } = request
    { owner, uuid } = request.params
    return response.status(403).send({ error: 'Forbidden' }) unless meshbluAuth?
    @upgradeConnectorService.do { body, meshbluAuth, uuid, owner }, (error) =>
      return response.sendError(error) if error?
      response.sendStatus(204)

module.exports = MeshbluConnectorController

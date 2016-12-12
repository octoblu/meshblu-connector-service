MeshbluHttp = require 'meshblu-http'

class MeshbluConnectorService
  constructor: ({ @schemaService }) ->
    throw new Error 'Router: requires schemaService' unless @schemaService?

  create: ({ name, connector, type, githubSlug, version, owner, meshbluAuth }, callback) =>
    @schemaService.get { githubSlug, version }, (error, schemas) =>
      return callback error if error?
      meshbluHttp = new MeshbluHttp meshbluAuth
      properties = {
        name,
        type,
        connector,
        owner,
        schemas,
        discoverWhitelist: [owner]
        configureWhitelist: [owner]
        sendWhitelist: [owner]
        receiveWhitelist: [owner]
        connectorMetadata: {
          version,
          githubSlug,
          stopped: false
        }
      }
      meshbluHttp.register properties, (error, device) =>
        return callback(error) if error?
        callback()

  _createError: (code, message) =>
    error = new Error message
    error.code = code if code?
    return error

module.exports = MeshbluConnectorService

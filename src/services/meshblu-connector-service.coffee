_           = require 'lodash'
MeshbluHttp = require 'meshblu-http'

class MeshbluConnectorService
  constructor: ({ @schemaService }) ->
    throw new Error 'Router: requires schemaService' unless @schemaService?

  create: ({ body, meshbluAuth }, callback) =>
    validationError = @_validateBody body
    return callback(validationError) if validationError?
    { githubSlug, version, owner } = body
    meshbluHttp = new MeshbluHttp meshbluAuth
    @schemaService.get { githubSlug, version }, (error, schemas) =>
      return callback error if error?
      @_createConnectorDevice { body, meshbluHttp, schemas }, (error, device) =>
        return callback error if error?
        { uuid } = device
        @_createStatusDevice { uuid, owner, meshbluHttp }, (error, statusDevice) =>
          return callback error if error?
          @_updateDevice { device, statusDevice, meshbluHttp }, (error) =>
            return callback error if error?
            callback null, device

  _createConnectorDevice: ({ body, meshbluHttp, schemas }, callback) =>
    { name, connector, type, githubSlug, version } = body
    { regsitryItem, owner } = body
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
    _.set properties, 'octoblu.registryItem', registryItem if registryItem?
    meshbluHttp.register properties, callback

  _createStatusDevice: ({ owner, uuid, meshbluHttp }, callback) =>
    properties = {
      type: 'connector-status-device',
      owner: uuid,
      discoverWhitelist: [uuid, owner],
      configureWhitelist: [uuid, owner],
      sendWhitelist: [uuid, owner],
      receiveWhitelist: [uuid, owner],
    }
    meshbluHttp.register properties, callback

  _updateDevice: ({ statusDevice, device, meshbluHttp }, callback) =>
    query = {
      $set:
        statusDevice: statusDevice.uuid
      $addToSet:
        'octoblu.links':
          url: "https://connector-factory.octoblu.com/connectors/configure/#{device.uuid}"
          title: 'View in Connector Factory'
    }
    meshbluHttp.updateDangerously device.uuid, query, callback

  _validateBody: (body) =>
    return @_createError 'Create Connector: requires a post body', 422 unless body?
    return @_createError 'Create Connector: requires githubSlug in post body', 422 unless body.githubSlug?
    return @_createError 'Create Connector: requires owner in post body', 422 unless body.owner?
    return @_createError 'Create Connector: requires version in post body', 422 unless body.version?
    return @_createError 'Create Connector: requires name in post body', 422 unless body.name?
    return @_createError 'Create Connector: requires connector in post body', 422 unless body.connector?
    return @_createError 'Create Connector: requires type in post body', 422 unless body.type?
    return null

  _createError: (message, code) =>
    error = new Error message
    error.code = code if code?
    return error

module.exports = MeshbluConnectorService

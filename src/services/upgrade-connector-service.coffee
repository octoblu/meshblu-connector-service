_           = require 'lodash'
MeshbluHttp = require 'meshblu-http'

class UpgradeConnectorService
  constructor: ({ @schemaService }) ->
    throw new Error 'UpgradeConnectorService: requires schemaService' unless @schemaService?

  do: ({ body, uuid, meshbluAuth }, callback) =>
    validationError = @_validateBody body
    return callback(validationError) if validationError?
    { githubSlug, version, owner } = body
    meshbluHttp = new MeshbluHttp meshbluAuth
    @schemaService.get { githubSlug, version }, (error, schemas) =>
      return callback error if error?
      @_getConnectorDevice { uuid, meshbluHttp }, (error, device) =>
        return callback error if error?
        @_createStatusDevice { device, owner, meshbluHttp }, (error, statusDevice) =>
          return callback error if error?
          @_updateDevice { statusDevice, uuid, body, schemas, meshbluHttp }, callback

  _getConnectorDevice: ({ uuid, meshbluHttp }, callback) =>
    meshbluHttp.device uuid, callback

  _createStatusDevice: ({ owner, device, meshbluHttp }, callback) =>
    { uuid, statusDevice } = device
    return callback null if statusDevice?
    properties = {
      type: 'connector-status-device',
      owner: uuid,
      discoverWhitelist: [uuid, owner],
      configureWhitelist: [uuid, owner],
      sendWhitelist: [uuid, owner],
      receiveWhitelist: [uuid, owner],
    }
    meshbluHttp.register properties, callback

  _updateDevice: ({ uuid, statusDevice, body, schemas, meshbluHttp }, callback) =>
    query = {
      type: body.type
      connector: body.connector
      'connectorMetadata.version': body.version
      'connectorMetadata.githubSlug': body.githubSlug
      schemas: schemas
    }
    _.set query, 'statusDevice', statusDevice.uuid if statusDevice?.uuid?
    meshbluHttp.update uuid, query, callback

  _validateBody: (body) =>
    return @_createError 'Upgrade Connector: requires a post body', 422 unless body?
    return @_createError 'Upgrade Connector: requires githubSlug in post body', 422 unless body.githubSlug?
    return @_createError 'Upgrade Connector: requires owner in post body', 422 unless body.owner?
    return @_createError 'Upgrade Connector: requires version in post body', 422 unless body.version?
    return @_createError 'Upgrade Connector: requires name in post body', 422 unless body.name?
    return @_createError 'Upgrade Connector: requires connector in post body', 422 unless body.connector?
    return @_createError 'Upgrade Connector: requires type in post body', 422 unless body.type?
    return null

  _createError: (message, code) =>
    error = new Error message
    error.code = code if code?
    return error

module.exports = UpgradeConnectorService

_           = require 'lodash'
MeshbluHttp = require 'meshblu-http'

class UpgradeConnectorService
  constructor: ({ @schemaService, @connectorDetailService }) ->
    throw new Error 'UpgradeConnectorService: requires schemaService' unless @schemaService?
    throw new Error 'UpgradeConnectorService: requires connectorDetailService' unless @connectorDetailService?

  do: ({ body, uuid, meshbluAuth, owner }, callback) =>
    validationError = @_validateBody body
    return callback validationError if validationError?
    meshbluHttp = new MeshbluHttp meshbluAuth
    @_getConnectorDevice { uuid, meshbluHttp }, (error, device) =>
      return callback error if error?
      { githubSlug, version } = body
      body = @_createUpdateBody { device, body }
      validationError = @_validateUpdateBody body
      return callback validationError if validationError?
      @connectorDetailService.resolveVersion { version, githubSlug }, (error, version) =>
        return callback error if error?
        @schemaService.get { githubSlug, version }, (error, schemas) =>
          return callback error if error?
          @_createStatusDevice { device, owner, meshbluHttp }, (error, statusDevice) =>
            return callback error if error?
            @_updateDevice { statusDevice, version, uuid, body, schemas, meshbluHttp }, callback

  _getConnectorDevice: ({ uuid, meshbluHttp }, callback) =>
    meshbluHttp.device uuid, callback

  _createStatusDevice: ({ owner, device, meshbluHttp }, callback) =>
    { uuid, statusDevice } = device
    return callback null, { uuid: statusDevice } if statusDevice?
    properties = {
      type: 'connector-status-device',
      owner: uuid,
      discoverWhitelist: [uuid, owner],
      configureWhitelist: [uuid, owner],
      sendWhitelist: [uuid, owner],
      receiveWhitelist: [uuid, owner],
    }
    meshbluHttp.register properties, callback

  _updateDevice: ({ uuid, version, statusDevice, body, schemas, meshbluHttp }, callback) =>
    { githubSlug, name, connector, type } = body
    { registryItem, iconUri } = body
    properties = {
      type
      connector
      'connectorMetadata.version': version
      'connectorMetadata.githubSlug': githubSlug
      schemas
    }
    _.set properties, 'iconUri', iconUri if iconUri?
    _.set properties, 'name', name if name?
    _.set properties, 'statusDevice', statusDevice.uuid if statusDevice?.uuid?
    properties['octoblu.registryItem'] = registryItem if registryItem?
    properties['octoblu.registryItem'] = { githubSlug } unless registryItem?

    meshbluHttp.update uuid, properties, callback

  _createUpdateBody: ({ body, device }) =>
    return _.defaults body, {
      name: _.get(device, 'name')
      connector: _.get(device, 'connector')
      type: _.get(device, 'type')
      githubSlug: _.get(device, 'connectorMetadata.githubSlug')
    }

  _validateBody: (body) =>
    return @_createError 'Upgrade Connector: requires a post body', 422 unless body?
    return null

  _validateUpdateBody: (body) =>
    return @_createError 'Upgrade Connector: requires githubSlug in post body', 422 unless body.githubSlug?
    return @_createError 'Upgrade Connector: requires connector in post body', 422 unless body.connector?
    return @_createError 'Upgrade Connector: requires type in post body', 422 unless body.type?
    return null

  _createError: (message, code) =>
    error = new Error message
    error.code = code if code?
    return error

module.exports = UpgradeConnectorService

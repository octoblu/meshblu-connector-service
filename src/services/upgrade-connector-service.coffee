_           = require 'lodash'
MeshbluHttp = require 'meshblu-http'

class UpgradeConnectorService
  constructor: ({ @schemaService }) ->
    throw new Error 'UpgradeConnectorService: requires schemaService' unless @schemaService?

  do: ({ body, uuid, meshbluAuth }, callback) =>
    validationError = @_validateBody body
    return callback validationError if validationError?
    meshbluHttp = new MeshbluHttp meshbluAuth
    @_getConnectorDevice { uuid, meshbluHttp }, (error, device) =>
      return callback error if error?
      { githubSlug, version, owner } = body
      body = @_createUpdateBody { device, body }
      validationError = @_validateUpdateBody body
      return callback validationError if validationError?
      @schemaService.get { githubSlug, version }, (error, schemas) =>
        return callback error if error?
        @_createStatusDevice { device, owner, meshbluHttp }, (error, statusDevice) =>
          return callback error if error?
          @_updateDevice { statusDevice, uuid, body, schemas, meshbluHttp }, callback

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

  _updateDevice: ({ uuid, statusDevice, body, schemas, meshbluHttp }, callback) =>
    { githubSlug, name, version, connector, type, registryItem } = body
    properties = _.defaultsDeep {
      type
      connector
      'connectorMetadata.version': version
      'connectorMetadata.githubSlug': githubSlug
      schemas
    }, @schemaService.defaults({ schemas })
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
    return @_createError 'Upgrade Connector: requires owner in post body', 422 unless body.owner?
    return @_createError 'Upgrade Connector: requires version in post body', 422 unless body.version?
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
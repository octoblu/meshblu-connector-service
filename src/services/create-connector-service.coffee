_           = require 'lodash'
MeshbluHttp = require 'meshblu-http'

class CreateConnectorService
  constructor: ({ @schemaService, @connectorDetailService }) ->
    throw new Error 'CreateConnectorService: requires schemaService' unless @schemaService?
    throw new Error 'CreateConnectorService: requires connectorDetailService' unless @connectorDetailService?

  do: ({ body, meshbluAuth, owner }, callback) =>
    validationError = @_validateBody body
    return callback(validationError) if validationError?
    { githubSlug, version } = body
    meshbluHttp = new MeshbluHttp meshbluAuth
    @connectorDetailService.resolveVersion { version, githubSlug }, (error, version) =>
      return callback error if error?
      @schemaService.get { githubSlug, version }, (error, schemas) =>
        return callback error if error?
        @_createConnectorDevice { owner, body, version, meshbluHttp, schemas }, (error, device) =>
          return callback error if error?
          { uuid } = device
          @_createStatusDevice { uuid, owner, meshbluHttp }, (error, statusDevice) =>
            return callback error if error?
            @_updateDevice { device, statusDevice, meshbluHttp }, (error) =>
              return callback error if error?
              @_getConnectorDevice { uuid, meshbluHttp }, callback

  _getConnectorDevice: ({ uuid, meshbluHttp }, callback) =>
    meshbluHttp.device uuid, callback

  _createConnectorDevice: ({ owner, body, version, meshbluHttp, schemas }, callback) =>
    { name, connector, type, githubSlug } = body
    { registryItem, iconUri } = body
    meshblu = _.get(body, 'meshblu', { domain: 'octoblu.com' })
    properties = _.defaultsDeep {
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
        stopped: false,
        meshblu,
      }
    }, @schemaService.defaultOptions({ schemas })
    _.set properties, 'name', name
    _.set properties, 'iconUri', iconUri if iconUri?
    _.set properties, 'octoblu.registryItem', registryItem if registryItem?
    _.set properties, 'octoblu.registryItem', {githubSlug} unless registryItem?
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
    return @_createError 'Create Connector: requires connector in post body', 422 unless body.connector?
    return @_createError 'Create Connector: requires type in post body', 422 unless body.type?
    return null

  _createError: (message, code) =>
    error = new Error message
    error.code = code if code?
    return error

module.exports = CreateConnectorService

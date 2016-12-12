_           = require 'lodash'
MeshbluHttp = require 'meshblu-http'

class MeshbluConnectorService
  constructor: ({ @schemaService }) ->
    throw new Error 'Router: requires schemaService' unless @schemaService?

  create: ({ body, meshbluAuth }, callback) =>
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

  _createError: (code, message) =>
    error = new Error message
    error.code = code if code?
    return error

module.exports = MeshbluConnectorService

_           = require 'lodash'
async       = require 'async'
request     = require 'request'
MeshbluHttp = require 'meshblu-http'

class OtpService
  constructor: ({ @meshbluOtpUrl, @connectorDetailService }) ->
    throw new Error 'OtpService: requires meshbluOtpUrl' unless @meshbluOtpUrl?
    throw new Error 'OtpService: requires connectorDetailService' unless @connectorDetailService?

  generate: ({ uuid, meshbluAuth }, callback) =>
    meshbluHttp = new MeshbluHttp meshbluAuth
    meshbluHttp.device uuid, (error, device) =>
      return callback error if error?
      meshbluHttp.generateAndStoreToken uuid, (error, result) =>
        return callback error if error?
        { token } = result
        @_resolveVersions (error, versions) =>
          return callback error if error?
          @_generatePassword { uuid, token, device, versions }, callback

  _createError: (message, code) =>
    error = new Error message
    error.code = code
    error.code ?= 500
    return error

  _generatePassword: ({ uuid, token, device, versions }, callback) =>
    request.post {
      baseUrl: @meshbluOtpUrl
      uri: '/v2/passwords'
      auth:
        username: uuid
        password: token
      json: @_getMetadata { device, versions }
    }, (error, response, body) =>
      return callback error if error?
      if response.statusCode > 399
        return callback @_createError 'Invalid response from Otp service', response.statusCode
      { key } = body
      callback null, { key }

  _getConnectorName: ({ connector = '' }) =>
    return connector.replace(/^meshblu-(connector-)/, '')

  _getConnectorVersion: (device) =>
    version = _.get device, 'connectorMetadata.version'
    version ?= ''
    version = version.replace('v', '')
    return "v#{version}"

  _getMetadata: ({ device, versions }) =>
    return {
      connector: @_getConnectorName device
      tag: @_getConnectorVersion device
      githubSlug: _.get device, 'connectorMetadata.githubSlug'
      installerVersion: _.get versions, 'installerVersion'
      ignitionVersion: _.get versions, 'ignitionVersion'
      octoblu: {}
      meshblu: _.get device, 'connectorMetadata.meshblu', { domain: 'octoblu.com' }
    }

  _resolveVersions: (callback) =>
    async.parallel {
      installerVersion: async.apply @connectorDetailService.resolveVersion, { githubSlug: 'octoblu/go-meshblu-connector-installer' }
      ignitionVersion: async.apply @connectorDetailService.resolveVersion, { githubSlug: 'octoblu/go-meshblu-connector-ignition' }
    }, callback

module.exports = OtpService

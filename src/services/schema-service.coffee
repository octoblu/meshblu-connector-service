_                  = require 'lodash'
request            = require 'request'
jsonSchemaDefaults = require 'json-schema-defaults'

class SchemaService
  constructor: ({ @fileDownloaderUrl, @connectorDetailService }) ->
    throw new Error 'SchemaService: requires fileDownloaderUrl' unless @fileDownloaderUrl?
    throw new Error 'SchemaService: requires connectorDetailService' unless @connectorDetailService?

  get: ({ githubSlug, version }, callback) =>
    @connectorDetailService.getLatestTag { githubSlug, version }, (error, version) =>
      return callback error if error?
      request.get {
        baseUrl: @fileDownloaderUrl
        uri: "/github-release/#{githubSlug}/#{version}/schemas.json"
        json: true
      }, (error, response, body) =>
        return callback error if error?
        return callback @_createError('Invalid fetch schema response', response.statusCode) if response.statusCode > 399
        callback null, _.get(body, 'schemas', {})

  defaultOptions: ({ schemas }) =>
    key = @getDefaultSchemaKey({ schemas })
    return unless key?
    defaultSchema = schemas.configure[key]
    return if _.isEmpty defaultSchema
    options = jsonSchemaDefaults(defaultSchema) ? {}
    _.set options, 'schemas.selected.configure', key
    return options

  getDefaultSchemaKey: ({ schemas }) =>
    return unless schemas?.configure?
    keys = _.keys(schemas.configure)
    return _.first(keys) if _.size(keys) == 1
    return 'Default' if schemas.configure.Default?
    return 'default' if schemas.configure.default?

  _createError: (code, message) =>
    error = new Error message
    error.code = code if code?
    return error

module.exports = SchemaService

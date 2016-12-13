_                  = require 'lodash'
request            = require 'request'
jsonSchemaDefaults = require 'json-schema-defaults'

class SchemaService
  constructor: ({ @fileDownloaderUrl }) ->
    throw new Error 'SchemaService: requires fileDownloaderUrl' unless @fileDownloaderUrl

  get: ({ githubSlug, version }, callback) =>
    request.get {
      baseUrl: @fileDownloaderUrl
      uri: "/github-release/#{githubSlug}/#{version}/schemas.json"
      json: true
    }, (error, response, body) =>
      return callback error if error?
      return callback @_createError('Invalid fetch schema response', response.statusCode) if response.statusCode > 399
      callback null, _.get(body, 'schemas', {})

  defaults: ({ schemas }) =>
    defaultSchema = @_findDefaultSchema({ schemas })
    return null if _.isEmpty defaultSchema
    return jsonSchemaDefaults defaultSchema

  _findDefaultSchema: ({ schemas }) =>
    return null unless schemas?.configure?
    keys = _.keys(schemas.configure)
    return _.get(schemas, "configure.#{_.first(keys)}") if _.size(keys) == 1
    return _.get(schemas, 'configure.Default', _.get(schemas, 'configure.default'))

  _createError: (code, message) =>
    error = new Error message
    error.code = code if code?
    return error

module.exports = SchemaService

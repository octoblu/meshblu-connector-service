_       = require 'lodash'
request = require 'request'

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

  _createError: (code, message) =>
    error = new Error message
    error.code = code if code?
    return error

module.exports = SchemaService

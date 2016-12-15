_                  = require 'lodash'
request            = require 'request'

class ConnectorDetailService
  constructor: ({ @connectorDetailUrl }) ->
    throw new Error 'ConnectorDetailService: requires connectorDetailUrl' unless @connectorDetailUrl

  resolveVersion: ({ githubSlug, version }, callback) =>
    return callback @_createError('Invalid type for version', 422) if version? and !_.isString(version)
    request.get {
      baseUrl: @connectorDetailUrl
      uri: "/github/#{githubSlug}"
      json: true
    }, (error, response, body) =>
      return callback error if error?
      return callback @_createError('Invalid get latest schema', response.statusCode) if response.statusCode > 399
      return @_getLatestFromBody { body }, callback unless version?
      return @_getLatestFromBody { body}, callback if version == 'latest'
      return @_resolveVersionInBody { body, version }, callback

  _getLatestFromBody: ({ body }, callback) =>
    foundTag = _.get(body, 'latest.tag')
    return callback @_createError('No latest tag', 404) unless foundTag?
    callback null, foundTag

  _resolveVersionInBody: ({ body, version }, callback) =>
    foundTag = body.tags[version]
    return callback @_createError("#{version} is does not exist", 404) unless foundTag?
    return callback @_createError("#{version} (prerelease) is invalid", 406) if foundTag.prerelease
    return callback @_createError("#{version} (draft) is invalid", 406) if foundTag.draft
    callback null, version

  _createError: (message, code) =>
    error = new Error message
    error.code = code if code?
    return error

module.exports = ConnectorDetailService

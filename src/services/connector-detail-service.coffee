_                  = require 'lodash'
request            = require 'request'

class ConnectorDetailService
  constructor: ({ @connectorDetailUrl }) ->
    throw new Error 'ConnectorDetailService: requires connectorDetailUrl' unless @connectorDetailUrl

  getLatestTag: ({ githubSlug, version }, callback) =>
    return callback null, version if version? and version != 'latest'
    request.get {
      baseUrl: @connectorDetailUrl
      uri: "/github/#{githubSlug}"
      json: true
    }, (error, response, body) =>
      return callback error if error?
      return callback @_createError('Invalid get latest schema', response.statusCode) if response.statusCode > 399
      foundTag = _.get(body, 'latest.tag')
      return callback @_createError('No latest tag', 404) unless foundTag?
      callback null, foundTag

  _createError: (code, message) =>
    error = new Error message
    error.code = code if code?
    return error

module.exports = ConnectorDetailService

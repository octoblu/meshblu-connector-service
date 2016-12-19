_                  = require 'lodash'
request            = require 'request'

class ConnectorDetailService
  constructor: ({ @githubToken, @githubApiUrl }) ->
    throw new Error 'ConnectorDetailService: requires githubToken' unless @githubToken?
    throw new Error 'ConnectorDetailService: requires githubApiUrl' unless @githubApiUrl?

  resolveVersion: ({ githubSlug, version }, callback) =>
    return callback @_createError('Invalid type for version', 422) if version? and !_.isString(version)
    return @_getLatestVersion { githubSlug } unless version?
    return @_getLatestVersion { githubSlug } if version == 'latest'
    return @_get { githubSlug, version } unless version?

  _getLatestVersion: ({ githubSlug }, callback) =>
    options =
      baseUrl: @githubApiUrl
      uri: "/repos/#{githubSlug}/releases/latest"
      headers:
        'User-Agent': 'Meshblu Connector Service'
        'Authorization': "token #{@githubToken}"
      json: true

    request.get options, (error, response, latest) =>
      return callback @_createError error.message, 500 if error?
      return callback @_createError bodyResponse.message, response.statusCode if response.statusCode > 299
      version = latest?.tag_name
      return callback @_createError 'No latest version available', 404 unless version?
      return callback null, latest?.tag_name

  _get: ({ githubSlug, version }, callback) =>
    options =
      baseUrl: @githubApiUrl
      uri: "/repos/#{githubSlug}/releases"
      headers:
        'User-Agent': 'Meshblu Connector Service'
        'Authorization': "token #{@githubToken}"
      json: true

    request.get options, (error, response, releases) =>
      return callback @_createError error.message, 500 if error?
      return callback @_createError bodyResponse.message, response.statusCode if response.statusCode > 299
      release = _.find releases, { tag_name: version }
      @_validateRelease release, callback

  _validateRelease: ({ tag_name, prerelease, draft }, callback) =>
    version = tag_name
    return callback @_createError("#{version} is does not exist", 404) unless foundTag?
    return callback @_createError("#{version} (prerelease) is invalid", 406) if foundTag.prerelease
    return callback @_createError("#{version} (draft) is invalid", 406) if foundTag.draft
    callback null, version

  _createError: (message, code) =>
    error = new Error message
    error.code = code if code?
    return error

module.exports = ConnectorDetailService

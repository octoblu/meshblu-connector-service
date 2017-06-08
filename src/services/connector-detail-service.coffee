_                  = require 'lodash'

class ConnectorDetailService
  constructor: ({ @githubToken, @githubApiUrl, @cachedRequest }) ->
    throw new Error 'ConnectorDetailService: requires githubToken' unless @githubToken?
    throw new Error 'ConnectorDetailService: requires githubApiUrl' unless @githubApiUrl?
    throw new Error 'ConnectorDetailService: requires cachedRequest' unless @cachedRequest?

  resolveVersion: ({ githubSlug, version }, callback) =>
    return callback @_createError('Invalid type for version', 422) if version? and !_.isString(version)
    return @_getLatestVersion { githubSlug }, callback unless version?
    return @_getLatestVersion { githubSlug }, callback if version == 'latest'
    return @_get { githubSlug, version }, callback

  _getLatestVersion: ({ githubSlug }, callback) =>
    options =
      baseUrl: @githubApiUrl
      uri: "/repos/#{githubSlug}/releases/latest"
      headers:
        'User-Agent': 'Meshblu Connector Service'
        'Authorization': "token #{@githubToken}"
      json: true

    requestId = "#{@githubApiUrl}/repos/#{githubSlug}/releases/latest"

    @cachedRequest.get requestId, options, (error, latest) =>
      return callback @_createError error.message, error.code if error?
      version = latest?.tag_name
      return callback @_createError('No latest version available', 404) unless version?
      callback null, version

  _get: ({ githubSlug, version }, callback) =>
    options =
      baseUrl: @githubApiUrl
      uri: "/repos/#{githubSlug}/releases"
      headers:
        'User-Agent': 'Meshblu Connector Service'
        'Authorization': "token #{@githubToken}"
      json: true

    requestId = "#{@githubApiUrl}/repos/#{githubSlug}/releases"
    @cachedRequest.get requestId, options, (error, releases) =>
      return callback @_createError error.message, error.code if error?
      release = _.find releases, { tag_name: version }
      @_validateRelease release, callback

  _validateRelease: ({ tag_name, prerelease, draft } = {}, callback) =>
    version = tag_name
    return callback @_createError("#{version} is does not exist", 404) unless version?
    return callback @_createError("#{version} (prerelease) is invalid", 406) if prerelease
    return callback @_createError("#{version} (draft) is invalid", 406) if draft
    callback null, version

  _createError: (message, code=500) =>
    error = new Error message
    error.code = code if code?
    return error

module.exports = ConnectorDetailService

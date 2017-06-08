_         = require 'lodash'
request   = require 'request'
debug     = require('debug')('meshblu-connector-service:cache-request')

class CachedRequest
  constructor: ({@redis,@redisKeyPrefix}) ->
    throw new Error 'CachedRequest requires redis' unless @redis?
    throw new Error 'CachedRequest requires redisKeyPrefix' unless @redisKeyPrefix?

  get: (requestId, options, callback) =>
    debug 'get requestId', requestId
    @redis.get "cache:url:#{requestId}", (error, result) =>
      return callback error if error?
      return callback null, JSON.parse(result) if result?
      @_get options, (error, body) =>
        return callback error if error?
        @redis.setex "cache:url:#{requestId}", 60, JSON.stringify(body), (error) =>
          callback error, body

  clearCache: =>
    @redis.keys "#{@redisKeyPrefix}cache:url:*", (error, keys) =>
      console.error error if error?
      return if _.isEmpty keys
      @redis.del keys

  _get: (options, callback) =>
    options.gzip ?= true
    options.json ?= true
    request.get options, (error, response, body) =>
      return callback error if error?
      if response.statusCode > 299
        error = new Error "Unexpected non 2xx status code: #{response.statusCode}"
        error.code = response.statusCode
        return callback error
      callback null, body

module.exports = CachedRequest

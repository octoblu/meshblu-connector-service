enableDestroy      = require 'server-destroy'
octobluExpress     = require 'express-octoblu'
MeshbluAuth        = require 'express-meshblu-auth'
Router             = require './router'
MeshbluConnectorService = require './services/meshblu-connector-service'
debug              = require('debug')('meshblu-connector-service:server')

class Server
  constructor: ({@logFn, @disableLogging, @port, @meshbluConfig})->
    throw new Error 'Missing meshbluConfig' unless @meshbluConfig?

  address: =>
    @server.address()

  run: (callback) =>
    app = octobluExpress({ @logFn, @disableLogging })

    meshbluAuth = new MeshbluAuth @meshbluConfig
    app.use meshbluAuth.auth()
    app.use meshbluAuth.gateway()

    meshbluConnectorService = new MeshbluConnectorService
    router = new Router {@meshbluConfig, meshbluConnectorService}

    router.route app

    @server = app.listen @port, callback
    enableDestroy @server

  stop: (callback) =>
    @server.close callback

  destroy: =>
    @server.destroy()

module.exports = Server

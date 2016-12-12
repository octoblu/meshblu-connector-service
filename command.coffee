_              = require 'lodash'
MeshbluConfig  = require 'meshblu-config'
SigtermHandler = require 'sigterm-handler'
Server         = require './src/server'

class Command
  constructor: ->
    @serverOptions = {
      meshbluConfig:  new MeshbluConfig().toJSON()
      port:           process.env.PORT || 80
      disableLogging: process.env.DISABLE_LOGGING == "true"
    }

  panic: (error) =>
    console.error error.stack
    process.exit 1

  run: =>
    # Use this to require env
    # @panic new Error('Missing required environment variable: ENV_NAME') if _.isEmpty @serverOptions.envName
    @panic new Error('Missing meshbluConfig') if _.isEmpty @serverOptions.meshbluConfig

    server = new Server @serverOptions
    server.run (error) =>
      return @panic error if error?

      {address,port} = server.address()
      console.log "MeshbluConnectorService listening on port: #{port}"

    sigtermHandler = new SigtermHandler({ events: ['SIGINT', 'SIGTERM']})
    sigtermHandler.handle server.stop

command = new Command()
command.run()

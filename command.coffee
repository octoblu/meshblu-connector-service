_              = require 'lodash'
envalid        = require 'envalid'
MeshbluConfig  = require 'meshblu-config'
SigtermHandler = require 'sigterm-handler'
Server         = require './src/server'

class Command
  constructor: ->
    @env = envalid.cleanEnv process.env, {
      PORT: envalid.num({ default: 80, devDefault: 3000 })
      DISABLE_LOGGING: envalid.bool({ default: false })
      FILE_DOWNLOADER_URL: envalid.url({ default: 'https://file-downloader.octoblu.com' })
      CONNECTOR_DETAIL_URL: envalid.url({ default: 'https://connector.octoblu.com' })
    }

  panic: (error) =>
    console.error error.stack
    process.exit 1

  run: =>
    server = new Server {
      meshbluConfig     : new MeshbluConfig().toJSON()
      port              : @env.PORT
      disableLogging    : @env.DISABLE_LOGGING
      fileDownloaderUrl : @env.FILE_DOWNLOADER_URL
      connectorDetailUrl: @env.CONNECTOR_DETAIL_URL
    }
    server.run (error) =>
      return @panic error if error?

      {address,port} = server.address()
      console.log "MeshbluConnectorService listening on port: #{port}"

    sigtermHandler = new SigtermHandler({ events: ['SIGINT', 'SIGTERM']})
    sigtermHandler.register server.stop

command = new Command()
command.run()

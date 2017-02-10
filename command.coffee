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
      GITHUB_API_URL: envalid.url({ default: 'https://api.github.com' })
      MESHBLU_Otp_URL: envalid.url({ default: 'https://meshblu-otp.octoblu.com' })
      GITHUB_TOKEN: envalid.str()
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
      githubApiUrl      : @env.GITHUB_API_URL
      githubToken       : @env.GITHUB_TOKEN
      meshbluOtpUrl     : @env.MESHBLU_Otp_URL
    }
    server.run (error) =>
      return @panic error if error?

      {port} = server.address()
      console.log "MeshbluConnectorService listening on port: #{port}"

    sigtermHandler = new SigtermHandler({ events: ['SIGINT', 'SIGTERM']})
    sigtermHandler.register server.stop

command = new Command()
command.run()

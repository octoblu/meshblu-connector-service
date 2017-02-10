MeshbluHttp = require 'meshblu-http'

class OTPService
  constructor: ({ @meshbluOTPUrl }) ->
    throw new Error 'OTPService: requires meshbluOTPUrl' unless @meshbluOTPUrl?

  generate: ({ uuid, meshbluAuth }, callback) =>
    meshbluHttp = new MeshbluHttp meshbluAuth
    meshbluHttp.device uuid, (error) =>
      callback error

module.exports = OTPService

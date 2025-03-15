# frozen_string_literal: true

require_relative 'lib/LogDevice'
require_relative 'lib/WebServer'
require_relative 'lib/Router'

log_device = LogDevice.new
router = Router.new(log_device)
web_server = WebServer.new(log_device, router)

web_server.start_server

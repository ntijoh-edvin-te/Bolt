# frozen_string_literal: true

require_relative 'lib/Server'
require_relative 'lib/Router'
require 'logger'

LOGGER = Logger.new($stdout)
LOGGER.level = Logger::INFO
LOGGER.formatter = proc do |_, _, _, msg|
    "#{msg}\n"
end

router = Router.new(LOGGER)
Server.new(LOGGER, router)

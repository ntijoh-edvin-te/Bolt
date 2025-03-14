require_relative 'lib/Server'
require_relative 'lib/Router'
require 'logger'

LOGGER = Logger.new(STDOUT)
LOGGER.level = Logger::INFO
LOGGER.formatter = proc do |_, _, _, msg|
    "#{msg}\n"
end

router = Router.new(LOGGER)

router.add_route('/', true)
router.add_route('/login', false)
router.add_route('/register', false)

server = Server.new(LOGGER, router)

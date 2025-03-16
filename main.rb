require_relative 'lib/LogDevice'
require_relative 'lib/Server'
require_relative 'lib/Router'
require_relative 'config/database'
require_relative 'app/routes/routes'
require_relative 'app/routes/auth'
require_relative 'app/routes/profile'
require_relative 'app/routes/feed'

Database.connect

log_device = LogDevice.new
router = Router.new(log_device)

router.scope '/' do
    Routes.auth(router)
    Routes.profile(router)
    Routes.feed(router)
end

server = Server.new(log_device, router)
server.start_server

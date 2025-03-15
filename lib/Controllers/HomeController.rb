require_relative 'Controller'
require_relative '../Objects/Response'

class HomeController < Controller
    def initialize(logger)
        @logger = logger
    end

    def index(action, middleware, request)
        response = Response.new
        response.status_code = 200
        response.headers['Content-Type'] = 'text/html'
        response.body = '<h1>Hello, World!</h1>'

        response
    end
end

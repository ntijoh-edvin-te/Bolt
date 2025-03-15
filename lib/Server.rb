# frozen_string_literal: true

require 'socket'
require_relative 'controllers/HomeController'
require_relative 'controllers/AuthController'
require_relative 'controllers/ProfileController'
require_relative 'controllers/Controller'
require_relative 'Request'

class Server
    def initialize(logger, router, port = 8000)
        @logger = logger
        @logger.info("Server started on port: #{port}.")

        tcp_server = TCPServer.new('localhost', port)

        begin
            flow(tcp_server, router)
        rescue Exception => e
            @logger.error("Server error: #{e}")
            @logger.info('Server restarting...')
            tcp_server.close
            sleep(3)
            retry
        end
    end

    private

    def flow(tcp_server, router)
        while (session = tcp_server.accept)
            @logger.info("New connection: #{session.peeraddr(:numeric)[2]}.")

            request = Request.new(@logger, session)
            route = router.route(request)
            cookies = request.content['Cookies']
            auth_key = cookies ? get_auth_key(cookies) : nil
            auth_keys = 'resources/auth/auth_keys.txt'
            request_role = get_request_role(auth_key, auth_keys)
            puts route
            controller =
                case route[:controller]
                when 'HomeController' && isAllowed?(route, request_role)
                    HomeController.new
                when 'AuthController' && isAllowed?(route, request_role)
                    AuthController.new
                when 'ProfileController' && isAllowed?(route, request_role)
                    ProfileController.new
                else
                    Controller.new
                end

            puts route
        end
    end

    def isAllowed?(route, request_role)
        route[:allowed_roles].include?(request_role)
    end

    def get_auth_key(cookies)
        cookies.each do |cookie|
            return cookie.split('=')[1] if cookie.include?('auth_key')
        end
    end

    def get_request_role(auth_key, auth_keys)
        isAuthenticated?(auth_key, auth_keys) ? 'user' : 'guest'
    end

    def isAuthenticated?(auth_key, auth_keys)
        return false unless auth_key

        begin
            File.foreach(auth_keys).any? { |line| line.chomp == auth_key }
        rescue Exception => e
            @logger.info("Authentication failed: #{e}")
            false
        end
    end
end

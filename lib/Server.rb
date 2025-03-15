# frozen_string_literal: true

require 'socket'
require_relative 'Objects/Request'
require_relative 'controllers/HomeController'
require_relative 'controllers/AuthController'
require_relative 'controllers/ProfileController'

class Server
    # This class is responsible for starting the server and handling incoming connections.

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

    def flow(tcp_server, router)
        while (session = tcp_server.accept)
            @logger.info("New connection: #{session.peeraddr(:numeric)[2]}.")

            payload = []

            while (line = session.gets)
                payload << line
                break if line == "\r\n"
            end

            if payload.empty? || !payload[0].include?('HTTP')
                @logger.info('Empty payload or HTTP request.')
                session.close
                return
            end

            content_length = 0
            payload.each do |line|
                if line.downcase.start_with?('content-length:')
                    content_length = line.split(':', 2)[1].strip.to_i
                    break
                end
            end

            payload << session.read(content_length) if content_length.positive?

            request = Request.new(payload, @logger)
            route = router.route(request)

            controller =
                case route[:controller]
                when 'HomeController'
                    HomeController.new(@logger)
                when 'UserController'
                    UserController.new(@logger)
                else
                    Controller.new(@logger)
                end

            @logger.info("Route: #{route[:controller]}##{route[:action]}.")
            response = controller.send(route[:action], route[:middleware], request)

            session.print(response)
        end
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

# frozen_string_literal: true

require 'socket'
require_relative 'Parser'

class Server
    attr_reader :logger, :router

    def initialize(logger, router)
        @logger = logger
        @router = router
        @tracker = 1
    end

    def start_server(port = 8000)
        logger.call("Starting: http://localhost:#{port}")

        socket = TCPServer.new('localhost', port)
        session_handler(socket)
    end

    private

    def session_handler(socket)
        while (session = socket.accept)
            logger.call("Session ID: #{@tracker}", 0)
            @tracker += 1
            begin
                request = Parser.new(logger, session)
                resoinse = router.route(request)
            rescue Exception => e
                logger.call("#{e.message}", 2)
            ensure
                session.close
            end
        end
    end
end

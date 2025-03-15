# frozen_string_literal: true

require 'socket'
require_relative 'Request'
require_relative 'Router'
require_relative 'AuthContext'

class Server
    def initialize(log_device)
        start_server(8000)
    end

    private

    def log

    def start_server(port)
        socket = TCPServer.new('localhost', port)
        session_handler(socket)
    end

    def session_handler(socket)
        while (session = socket.accept)
            @logger.info("New connection: #{session.peeraddr(:numeric)[2]}.")
            begin
                request = Request.new(@logger, session)
                route = @router.route(request)
                auth_context = AuthContext.new(@logger, request)
            rescue Exception => e
                @logger.error("Request processing error: #{e}")
            ensure
                session.close
            end
        end
    end
end

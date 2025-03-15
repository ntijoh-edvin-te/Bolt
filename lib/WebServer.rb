# frozen_string_literal: true

require 'socket'
require_relative 'Request'
require_relative 'AuthContext'

class WebServer
    attr_reader :log_device, :router

    def initialize(log_device, router)
        @log_device = log_device
        @router = router
    end

    def start_server(port = 8080)
        log_device.log("Server is starting: http://127.0.0.1:#{port}")
        socket = TCPServer.new('localhost', port)
        session_handler(socket)
    end

    private

    def session_handler(socket)
        while (session = socket.accept)
            begin
                request = Request.new(@logger, session)
                route = @router.route(request)
                auth_context = AuthContext.new(@logger, request)
            rescue Exception => e
            ensure
                session.close
            end
        end
    end
end

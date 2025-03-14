# frozen_string_literal: true

require 'socket'
require_relative 'Request'

class Server
    def initialize(logger, router, port = 8000)
        @logger = logger
        @logger.info('Server started on port: ' + port.to_s + '.')

        tcp_server = TCPServer.new('localhost', port)

        begin
            start(tcp_server, router)
        rescue Exception => e
            @logger.error("Server error: #{e}")
            @logger.info('Server restarting...')
            wait(3)
            tcp_server.close
            retry
        end
    end

    def start(tcp_server, router)
        while (session = tcp_server.accept)
            @logger.info('New connection: ' + session.peeraddr(:numeric)[2] + '.')
            payload = []
            while (line = session.gets)
                payload << line
                break if line == "\r\n"
            end

            content_length = 0
            payload.each do |line|
                if line.downcase.start_with?('content-length:')
                    content_length = line.split(':', 2)[1].strip.to_i
                    break
                end
            end

            if content_length.positive?
                body = session.read(content_length)
                payload << body
            end

            request = Request.new(payload, @logger)

            begin
                auth_keys_path = 'resources/auth_keys.txt'
                auth_key = request.content['Headers']['Cookie'][/auth_key=([a-zA-Z0-9]{32})/, 1]
            rescue Exception => e
                auth_key = nil
            ensure
                auth = isAuthenticated?(auth_key, auth_keys_path) || false
            end

            @logger.info('Routing request...')
            response = router.route(request, auth)

            if response
                @logger.info('Sending response...')
                session.print response
            else
                @logger.info('Got no response...')
            end
        end
    end

    def isAuthenticated?(auth_key, auth_keys)
        return false unless auth_key

        begin
            File.foreach(auth_keys).any? { |line| line.chomp == auth_key }
        rescue Exception => e
            @logger.info("Authentication error: #{e}")
            false
        end
    end
end

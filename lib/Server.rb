# frozen_string_literal: true

require 'socket'
require_relative 'Router'
require_relative 'Request'

class Server
    def initialize
        @server = TCPServer.new('localhost', 8000)
        @counter = 0
        start
    end

    def start
        router = Router.new
        router.add_route('/', true)
        router.add_route('/login', false)
        router.add_route('/register', false)

        while (session = @server.accept)
            puts "Client 1.#{@counter} connected..."
            @counter += 1

            begin
                puts 'Reading request...'
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

                request = Request.new(payload)

                begin
                    auth_key = request.content['Headers']['Cookie'][/auth_key=([a-zA-Z0-9]{32})/, 1]
                rescue Exception => e
                    puts "No auth key found: #{e}"
                    auth_key = nil
                end

                auth = isAuthenticated?(auth_key, 'resources/auth_keys.txt') || false

                puts 'Routing request...'
                response = router.route(request, auth)

                if response
                    puts 'Sending response...'
                    session.print response
                else
                    puts 'Got no response...'
                end
            rescue Exception => e
                puts "Server error: #{e}"
            ensure
                session.close
                puts "Session closed...\n\r"
            end
        end
    end

    def isAuthenticated?(auth_key, auth_keys)
        return false unless auth_key

        begin
            puts 'Checking auth key...'
            File.foreach(auth_keys).any? { |line| line.chomp == auth_key }
        rescue Exception => e
            puts "Authentication error: #{e}"
            false
        end
    end
end

Server.new

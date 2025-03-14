# frozen_string_literal: true

require 'digest'
require 'securerandom'

class Response
    def initialize
        @html_resources = {
            '/' => 'resources/index.html',
            '/login' => 'resources/login.html',
            '/register' => 'resources/register.html'
        }
    end

    def get(request, auth)
        begin
            accepted_content_types = request.content['Headers']['Accept'].split(',')
        rescue StandardError
            accepted_content_types = ['text/html']
        end
        content_type = accepted_content_types.find { |t| ['text/html', 'text/plain'].include?(t) } || 'text/plain'
        resource = request.content['Resource'].split('?')[0]
        body = ''

        begin
            if ['/login', '/register'].include?(resource) && auth
                case content_type
                when 'text/html'
                    body = <<~HTML
                        <html>
                        	<body>
                        		<p>You're already logged in! <a href="/">Go to home</a></p>
                        	</body>
                        </html>
                    HTML
                when 'text/plain'
                    body = 'Already logged in. Visit /'
                end
            else
                case content_type
                when 'text/html'
                    file_path = @html_resources[resource]
                    body = File.read(file_path)
                when 'text/plain'
                    body = 'Hello, world!'
                end
            end
        rescue Errno::ENOENT
            return route_not_found
        end
        build_response(200, content_type, body)
    end

    def post(request, auth)
        resource = request.content['Resource'].split('?')[0]
        body = request.content['Body'] || {}
        username = body['username'].to_s
        password = body['password'].to_s

        # Redirect authenticated users trying to access auth endpoints
        return build_redirect('/') if ['/login', '/register'].include?(resource) && auth

        # Handle authentication logic
        if ['/login', '/register'].include?(resource) && !auth &&
           request.content['Headers']['Content-Type'] == 'application/x-www-form-urlencoded'

            user_hash = Digest::SHA256.hexdigest("#{username}#{password}")

            if username.empty?
                return build_response(400, 'text/plain', '')
            elsif resource == '/register'
                return handle_registration(username, user_hash)
            else
                return handle_login(user_hash)
            end
        end

        build_response(400, 'text/plain', '')
    end

    private

    def handle_registration(username, user_hash)
        if File.read('resources/usernames.txt').include?(username)
            build_response(409, 'text/plain', '')
        else
            File.write('resources/usernames.txt', "#{username}\n", mode: 'a')
            File.write('resources/users.txt', "#{user_hash}\n", mode: 'a')
            generated_key = SecureRandom.hex(16)
            File.write('resources/auth_keys.txt', "#{generated_key}\n", mode: 'a')

            response = build_response(201, 'text/plain', '')
            response.gsub!(/\r\n\r\n$/, "Set-Cookie: auth_key=#{generated_key}\r\nLocation: /\r\n\r\n")
            response
        end
    end

    def handle_login(user_hash)
        if File.read('resources/users.txt').include?(user_hash)
            generated_key = SecureRandom.hex(16)
            File.write('resources/auth_keys.txt', "#{generated_key}\n", mode: 'a')

            response = build_response(200, 'text/plain', '')
            response.gsub!(/\r\n\r\n$/, "Set-Cookie: auth_key=#{generated_key}\r\nLocation: /\r\n\r\n")
            response
        else
            build_response(401, 'text/plain', '')
        end
    end

    def build_response(status, content_type, body)
        headers = [
            "HTTP/1.1 #{status} #{status_label(status)}",
            "Content-Type: #{content_type}",
            "Content-Length: #{body.bytesize}",
            'Connection: close'
        ].join("\r\n")

        "#{headers}\r\n\r\n#{body}"
    end

    def build_redirect(location)
        headers = [
            'HTTP/1.1 302 Found',
            "Location: #{location}",
            'Connection: close'
        ].join("\r\n")

        "#{headers}\r\n\r\n"
    end

    def status_label(code)
        {
            200 => 'OK',
            201 => 'Created',
            302 => 'Found',
            400 => 'Bad Request',
            401 => 'Unauthorized',
            404 => 'Not Found',
            405 => 'Method Not Allowed',
            409 => 'Conflict',
            500 => 'Internal Server Error'
        }[code]
    end

    def method_not_allowed
        plain_body = 'Method not allowed'
        "HTTP/1.1 405 Method Not Allowed\r\n" \
          "Content-Type: text/plain\r\n" \
          "Content-Length: #{plain_body.bytesize}\r\n" \
          "Connection: close\r\n" \
          "\r\n" +
            plain_body
    end

    def route_not_found
        plain_body = 'Route not found'
        "HTTP/1.1 404 Not Found\r\n" \
          "Content-Type: text/plain\r\n" \
          "Content-Length: #{plain_body.bytesize}\r\n" \
          "Connection: close\r\n" \
          "\r\n" +
            plain_body
    end

    def unauthorized
        "HTTP/1.1 302 Found\r\n" \
          "Location: /login\r\n" \
          "Connection: close\r\n" \
          "\r\n"
    end

    def server_error
        plain_body = 'Internal server error'
        "HTTP/1.1 500 Internal Server Error\r\n" \
          "Content-Type: text/plain\r\n" \
          "Content-Length: #{plain_body.bytesize}\r\n" \
          "Connection: close\r\n" \
          "\r\n" +
            plain_body
    end
end

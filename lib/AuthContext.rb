class AuthContext
    attr_reader :auth_key, :role

    def initialize(logger, request)
        @logger = logger
        cookies = request.content['Cookies']
        @auth_key = extract_auth_key(cookies)
        @role = determine_role(@auth_key)
    end

    def allowed?(allowed_roles)
        allowed_roles.include?(@role)
    end

    private

    def extract_auth_key(cookies)
        return nil unless cookies

        cookies.find { |cookie| cookie.include?('auth_key') }&.split('=')&.[](1)
    end

    def determine_role(auth_key)
        authenticated?(auth_key) ? 'user' : 'guest'
    end

    def authenticated?(auth_key)
        return false unless auth_key

        begin
            File.foreach('resources/auth/auth_keys.txt').any? { |line| line.chomp == auth_key }
        rescue Exception => e
            @logger.info("Authentication failed: #{e}")
            false
        end
    end
end

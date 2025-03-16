class AuthController
    def login(req, params)
        {
            status: 200,
            headers: { 'Content-Type' => 'text/html' },
            body: render_template('auth/login.html')
        }
    end

    def perform_login(req, params)
        username = req.params['username']
        password = req.params['password']

        user = User.where(username: username).first

        if user && user.authenticate(password)
            # Authentication logic
            {
                status: 302,
                headers: { 'Location' => '/' },
                body: 'Redirecting to home...'
            }
        else
            {
                status: 401,
                headers: { 'Content-Type' => 'text/html' },
                body: render_template('auth/login.html', error: 'Invalid credentials')
            }
        end
    end

    def authenticated_user(req)
        session_token = req.cookies.find { |cookie| cookie.start_with?('session=') }&.split('=')&.last
        return nil unless session_token

        session = Session.where(token: session_token).first
        return nil unless session && session.expires_at > Time.now.to_i

        User.where(id: session.user_id).first
    end
end

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
end

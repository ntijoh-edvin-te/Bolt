class ProfileController
    def show(req, params)
        username = params[:username]
        user = User.where(username: username).first

        if user.nil?
            return {
                status: 404,
                headers: { 'Content-Type' => 'text/html' },
                body: 'User not found'
            }
        end

        if user.private_profile? && !authorized_to_view?(req, user)
            return {
                status: 403,
                headers: { 'Content-Type' => 'text/html' },
                body: 'Profile is private'
            }
        end

        {
            status: 200,
            headers: { 'Content-Type' => 'text/html' },
            body: render_template('profiles/show.html', user: user)
        }
    end

    private

    def authorized_to_view?(req, user)
        current_user = AuthController.new.authenticated_user(req)
        current_user && current_user.id == user.id
    end
end

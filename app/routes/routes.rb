module Routes
    def self.auth(router)
        router.get '/login', to: 'auth#login', as: :login
        router.post '/login', to: 'auth#perform_login', as: :perform_login
        router.delete '/logout', to: 'auth#logout', as: :logout
        router.get '/register', to: 'auth#register', as: :register
        router.post '/register', to: 'auth#perform_register', as: :perform_register
    end

    def self.profile(router)
        router.get '/@:username', to: 'profile#show', as: :public_profile
    end

    def self.home(router)
        router.get '/', to: 'home#index', as: :home
    end
end

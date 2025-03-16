module Routes
    def self.define_auth(router)
        router.get '/login', to: 'auth#login', as: :login
        router.post '/login', to: 'auth#perform_login', as: :perform_login
        router.delete '/logout', to: 'auth#logout', as: :logout
        router.get '/register', to: 'auth#register', as: :register
        router.post '/register', to: 'auth#perform_register', as: :perform_register
    end

    def self.define_profile(router)
        router.get '/@:username', to: 'profile#show', as: :public_profile
    end

    def self.define_home(router)
        router.get '/', to: 'home#index', as: :home
    end

    def self.define_resource_routes(router, name, options = {}, &block)
        base = name.to_s.downcase
        id_format = options[:constraints] || '[^\/]+'

        router.scope("/#{base}") do
            router.get('/', as: :index) if block_given?
            router.get('/new', as: :new)
            router.post('/', as: :create)
            router.get('/:id', constraints: { id: id_format }, as: :show)
            router.get('/:id/edit', constraints: { id: id_format }, as: :edit)
            router.patch('/:id', constraints: { id: id_format }, as: :update)
            router.put('/:id', constraints: { id: id_format }, as: :update)
            router.delete('/:id', constraints: { id: id_format }, as: :destroy)

            instance_eval(&block) if block_given?
        end
    end
end

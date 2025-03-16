require_relative 'routes'

module Routes
    def self.auth(router)
        router.scope '/auth' do
            router.get '/login', as: :login do |req, params|
            end

            router.post '/login', as: :perform_login do |req, params|
            end

            router.delete '/logout', as: :logout do |req, params|
            end

            router.get '/register', as: :register do |req, params|
            end

            router.post '/register', as: :perform_register do |req, params|
            end
        end
    end
end

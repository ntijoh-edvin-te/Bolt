require_relative 'routes'

module Routes
    def self.feed(router)
        router.get '/feed', as: :home_feed do |req, params|
        end
    end
end

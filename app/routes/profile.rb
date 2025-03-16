require_relative 'routes'

module Routes
    def self.profile(router)
        router.get '/@:username', as: :public_profile do |req, params|
        end
    end
end

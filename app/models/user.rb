require 'bcrypt'

class User < Sequel::Model
    def password=(password)
        @password = password
        self.password_hash = BCrypt::Password.create(password)
    end

    def authenticate(password)
        BCrypt::Password.new(password_hash) == password
    end
end

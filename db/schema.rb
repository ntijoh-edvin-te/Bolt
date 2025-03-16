module Schema
    def self.setup
        db = Database.db

        db.create_table? :users do
            primary_key :id
            String :username, null: false, unique: true
            String :password_hash, null: false
            DateTime :created_at
            DateTime :updated_at
        end

        db.create_table? :posts do
            primary_key :id
            foreign_key :user_id, :users
            String :image_path
            DateTime :created_at
            DateTime :updated_at
        end

        db.create_table? :sessions do
            primary_key :id
            foreign_key :user_id, :users
            String :token, null: false, unique: true
            DateTime :created_at
            Integer :expires_at
        end
    end
end

if defined?(Database.db)
    Schema.setup
end

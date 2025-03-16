require 'sequel'

module Database
    def self.connect
        @@db = Sequel.connect('sqlite://db/development.sqlite3')

        require_relative '../db/schema'

        @@db
    end

    def self.db
        @@db
    end
end

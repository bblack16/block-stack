module BlockStack
  module Database
    def self.databases
      @databases ||= {}
    end

    def self.db
      databases[primary_database] || databases.values.first
    end

    def self.primary_database
      @primary_database
    end

    def self.primary_database=(name)
      @primary_database = name.to_sym
    end

    def self.dbs
      databases
    end

    def self.setup(name, type, *args)
      databases[name.to_sym] = case type
      when :mongo
        require_relative 'model/adapters/mongo'
        Mongo::Client.new(*args)
      when :sqlite, :postgres, :mysql, :odbc, :oracle
        require_relative 'model/adapters/sql'
        db = Sequel.send(type, *args)
        db.loggers = [BlockStack.logger]
        db
      else
        raise ArgumentError, "Unknown database type '#{type}'."
      end
    end
  end
end

module DbSubsetter
  module Dialect
    # Dialect to subset to/from sqlite
    class Sqlite < Generic
      def self.integrity_problems
        ActiveRecord::Base.connection.execute('PRAGMA foreign_key_check')
      end
    end
  end
end

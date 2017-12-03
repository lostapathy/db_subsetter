module DbSubsetter
  module Dialect
    # Dialect to subset to/from postgres
    class Postgres < Generic
      def self.import
        ActiveRecord::Base.connection.execute('SET session_replication_role = replica;')
        yield
        ActiveRecord::Base.connection.execute('SET session_replication_role = DEFAULT;')
      end
    end
  end
end

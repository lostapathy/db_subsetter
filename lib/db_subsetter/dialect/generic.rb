module DbSubsetter
  module Dialect
    # Dialect to subset to/from database without explicit support
    class Generic
      def self.import
        yield
      end

      def self.integrity_problems
        []
      end

      def self.truncate_table(table)
        ActiveRecord::Base.connection.truncate(table)
      rescue NotImplementedError
        ActiveRecord::Base.connection.execute("DELETE FROM #{quoted_table_name(table)}")
      end
    end
  end
end

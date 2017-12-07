module DbSubsetter
  module Dialect
    # Dialect to subset to/from database without explicit support
    class Generic
      def self.import
        ActiveRecord::Base.connection.disable_referential_integrity do
          yield
        end
      end

      def self.integrity_problems
        raise NotImplementedError, 'integrity_problems not implemented for this dialect'
      end

      def self.truncate_table(table)
        ActiveRecord::Base.connection.truncate(table)
      rescue NotImplementedError
        ActiveRecord::Base.connection.execute("DELETE FROM #{table}")
      end
    end
  end
end

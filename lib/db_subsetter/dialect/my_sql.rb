module DbSubsetter
  module Dialect
    class MySQL < Generic
      def self.import
        ActiveRecord::Base.connection.execute("SET FOREIGN_KEY_CHECKS=0;")
        yield
        ActiveRecord::Base.connection.execute("SET FOREIGN_KEY_CHECKS=1;")
      end

      def self.integrity_problems
        raise NotImplementedError.new("integrity_problems not implemented for MySQL")
      end
    end
  end
end


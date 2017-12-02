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
    end
  end
end

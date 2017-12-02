module DbSubsetter
  module Dialect
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

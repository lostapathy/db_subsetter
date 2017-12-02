module DbSubsetter
  module Dialect
    # Dialect to subset to/from sqlite
    class Sqlite < Generic
      def self.import
        yield
      end

      def self.integrity_problems
        raise NotImplementedError, 'integrity_problems not implemented for sqlite'
      end
    end
  end
end

module DbSubsetter
  module Dialect
    # Dialect to subset to/from Microsoft SQL Server
    class MSSQL < Generic
      def self.integrity_problems
        ActiveRecord::Base.connection.execute('EXEC sp_msforeachtable "DBCC CHECKCONSTRAINTS WITH ALL_CONSTRAINTS"')
      end
    end
  end
end

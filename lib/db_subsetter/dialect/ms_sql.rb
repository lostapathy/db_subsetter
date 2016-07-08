module DbSubsetter
  module Dialect
    class MSSQL < Generic
      def self.import
        ActiveRecord::Base.connection.execute('EXEC sp_msforeachtable "ALTER TABLE ? NOCHECK CONSTRAINT all"')
        ActiveRecord::Base.connection.execute('EXEC sp_msforeachtable "ALTER TABLE ? DISABLE TRIGGER all"')

        yield
        ActiveRecord::Base.connection.execute('EXEC sp_msforeachtable "ALTER TABLE ? ENABLE TRIGGER all"')
        ActiveRecord::Base.connection.execute('EXEC sp_msforeachtable "ALTER TABLE ? WITH CHECK CHECK CONSTRAINT all"')
      end

      def self.integrity_problems
        ActiveRecord::Base.connection.execute('EXEC sp_msforeachtable "DBCC CHECKCONSTRAINTS WITH ALL_CONSTRAINTS"')
      end
    end
  end
end


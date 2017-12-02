module DbSubsetter
  module Dialect
    # Dialect to subset to/from Microsoft SQL Server
    class MSSQL < Generic
      def self.import
        ActiveRecord::Base.connection.execute('EXEC sp_msforeachtable "ALTER TABLE ? NOCHECK CONSTRAINT all"')
        ActiveRecord::Base.connection.execute('EXEC sp_msforeachtable "ALTER TABLE ? DISABLE TRIGGER all"')
        ActiveRecord::Base.connection.execute("select 'ALTER INDEX ' + I.name + ' ON ' + T.name + ' DISABLE'
            from sys.indexes I
            inner join sys.tables T on I.object_id = T.object_id
            where I.type_desc = 'NONCLUSTERED'
            and I.name is not null")

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

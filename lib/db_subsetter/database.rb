module DbSubsetter
  # A database to be exported from/to
  class Database
    def initialize(exporter)
      @exporter = exporter
    end

    def find_table(name)
      tables.select { |x| x.name == name }.first
    end

    def tables
      return @tables if @tables
      all_tables = ActiveRecord::Base.connection.tables
      table_list = all_tables - ActiveRecord::SchemaDumper.ignore_tables - @exporter.filter.ignore_tables

      @tables = table_list.map { |table_name| Table.new(table_name, self, @exporter) }
    end
  end
end

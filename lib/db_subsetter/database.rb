module DbSubsetter
  # A database to be exported from/to
  class Database
    def initialize(exporter)
      @exporter = exporter
    end

    def find_table(name)
      # FIXME: store table list as a hash internally to speed this up
      tables.select { |x| x.name == name }.first
    end

    def tables
      @tables ||= all_table_names.map { |table_name| Table.new(table_name, self, @exporter) }
    end

    def exported_tables
      tables.reject(&:ignored?)
    end

    # Raw list of names of all tables in the database.
    def all_table_names
      @all_table_names ||= ActiveRecord::Base.connection.tables
    end

    # Used in debugging/reporting
    def total_row_counts
      tables.map { |table| { table.name => table.total_row_count } }
    end

    # Used in debugging/reporting
    # FIXME: should probably omit tables that are not exported
    def filtered_row_counts
      tables.map { |table| { table.name => table.filtered_row_count } }
    end
  end
end

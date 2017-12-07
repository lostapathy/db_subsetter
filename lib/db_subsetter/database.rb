module DbSubsetter
  # A database to be exported from/to
  class Database
    def initialize(exporter)
      @exporter = exporter
      @tables = {}
      all_table_names.each { |table_name| @tables[table_name] = Table.new(table_name, self, @exporter) }
    end

    def find_table(name)
      @tables[name.to_s]
    end

    def tables
      @tables.values
    end

    def exported_tables
      tables.reject(&:ignored?)
    end

    # Raw list of names of all tables in the database.
    def all_table_names
      @all_table_names ||= ActiveRecord::Base.connection.tables - ['ar_internal_metadata']
    end

    # Used in debugging/reporting
    def total_row_counts
      tables.map { |table| [table.name, table.total_row_count] }.to_h
    end

    # Used in debugging/reporting
    def filtered_row_counts
      tables.map { |table| [table.name, table.filtered_row_count] }.to_h
    end

    def exportable?
      puts "Verifying table exportability ...\n\n" if @exporter.verbose?
      exported_tables.reject(&:exportable?).count.zero?
    end

    def exportability_issues
      exported_tables.reject(&:exportable?).map { |table| [table.name, table.exportability_issues] }.to_h
    end
  end
end

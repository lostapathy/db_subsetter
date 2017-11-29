require 'sqlite3'
require 'active_record'

module DbSubsetter
  class Exporter
    attr_writer :filter, :max_unfiltered_rows, :max_filtered_rows
    attr_reader :scramblers, :output

    def tables
      return @tables if @tables
      all_tables = ActiveRecord::Base.connection.tables
      table_list = all_tables - ActiveRecord::SchemaDumper.ignore_tables - @filter.ignore_tables

      @tables = table_list.map { |table_name| Table.new(table_name, exporter: self) }
    end

    def total_row_counts
      tables.each.map do |table|
        { table => table.total_row_count }
      end
    end

    def filtered_row_counts
      tables.each.map do |table|
        { table => table.filtered_row_count }
      end
    end

    def verify_exportability(verbose = true)
      puts "Verifying table exportability ...\n\n" if verbose
      errors = tables.map { |table| table.can_export? }.flatten.compact
      if errors.count > 0
        puts errors.join("\n")
        raise ArgumentError.new "Some tables are not exportable"
      end
      puts "\n\n" if verbose
    end

    def export(filename, verbose = true)
      @verbose = verbose
      verify_exportability(verbose)

      puts "Exporting data...\n\n" if @verbose
      @output = SQLite3::Database.new(filename)
      @output.execute("CREATE TABLE tables (name TEXT, records_exported INTEGER, columns TEXT)")
      tables.each do |table|
        table.export(verbose: @verbose)
      end
    end

    def add_scrambler(scrambler)
      @scramblers << scrambler
    end

    def initialize
      @scramblers = []
      @page_counts = {}
    end

    def select_batch_size
      insert_batch_size * 20
    end

    # this is the batch size we insert into sqlite, which seems to be a reasonable balance of speed and memory usage
    def insert_batch_size
      250
    end

    def filter
      @filter ||= Filter.new
      @filter.exporter = self
      @filter
    end

    def max_unfiltered_rows
      @max_unfiltered_rows || 1000
    end

    def max_filtered_rows
      @max_filtered_rows || 2000
    end
  end
end


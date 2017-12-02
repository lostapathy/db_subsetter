require 'sqlite3'
require 'active_record'

module DbSubsetter
  class Exporter
    attr_writer :filter, :max_unfiltered_rows, :max_filtered_rows
    attr_reader :scramblers, :output

    # this is the batch size we insert into sqlite, which seems to be a reasonable balance of speed and memory usage
    INSERT_BATCH_SIZE = 250
    SELECT_BATCH_SIZE = 5000

    def total_row_counts
      @database.tables.each.map do |table|
        { table => table.total_row_count }
      end
    end

    def filtered_row_counts
      @database.tables.each.map do |table|
        { table => table.filtered_row_count }
      end
    end

    def verify_exportability(verbose = true)
      puts "Verifying table exportability ...\n\n" if verbose
      errors = @database.tables.map { |table| table.can_export? }.flatten.compact
      if errors.count > 0
        puts errors.join("\n")
        raise ArgumentError.new 'Some tables are not exportable'
      end
      puts "\n\n" if verbose
    end

    def export(filename, verbose = true)
      @verbose = verbose
      verify_exportability(verbose)

      puts "Exporting data...\n\n" if @verbose
      @output = SQLite3::Database.new(filename)
      @output.execute 'CREATE TABLE tables (name TEXT, records_exported INTEGER, columns TEXT)'
      @database.tables.each do |table|
        table.export(verbose: @verbose)
      end
    end

    def add_scrambler(scrambler)
      @scramblers << scrambler
    end

    def initialize
      @scramblers = []
      @page_counts = {}
      @database = Database.new(self)
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


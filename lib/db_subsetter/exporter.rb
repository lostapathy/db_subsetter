require 'sqlite3'
require 'active_record'

module DbSubsetter
  class Exporter
    attr_writer :max_unfiltered_rows, :max_filtered_rows
    attr_reader :scramblers, :output, :database
    attr_accessor :filter

    # this is the batch size we insert into sqlite, which seems to be a reasonable balance of speed and memory usage
    INSERT_BATCH_SIZE = 250
    SELECT_BATCH_SIZE = 5000

    def verify_exportability(verbose = true)
      puts "Verifying table exportability ...\n\n" if verbose
      errors = @database.exported_tables.map { |table| table.can_export? }.flatten.compact
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
      @database.exported_tables.each do |table|
        table.export(verbose: @verbose)
      end
    end

    def add_scrambler(scrambler)
      @scramblers << scrambler
    end

    def ignore_tables(ignored)
      ignored.each do |t|
        @database.find_table(t).ignore!
      end
    end

    def initialize
      @scramblers = []
      @page_counts = {}
      @database = Database.new(self)
      @filter = Filter.new
    end

    def max_unfiltered_rows
      @max_unfiltered_rows || 1000
    end

    def max_filtered_rows
      @max_filtered_rows || 2000
    end
  end
end

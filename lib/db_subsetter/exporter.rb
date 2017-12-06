require 'sqlite3'
require 'active_record'

module DbSubsetter
  # Manages exporting a subset of data
  class Exporter
    attr_writer :max_unfiltered_rows, :max_filtered_rows
    attr_reader :scramblers, :output, :database
    attr_accessor :filter, :verbose
    alias verbose? verbose

    # this is the batch size we insert into sqlite, which seems to be a reasonable balance of speed and memory usage
    INSERT_BATCH_SIZE = 250
    SELECT_BATCH_SIZE = 5000

    def verify_exportability(verbose = true)
      puts "Verifying table exportability ...\n\n" if verbose
      errors = @database.exported_tables.map(&:exportable?).flatten.compact
      if errors.count > 0
        puts errors.join("\n")
        raise ArgumentError, 'Some tables are not exportable'
      end
      puts "\n\n" if verbose
    end

    def export(filename)
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

    def full_tables(full_tables)
      full_tables.each do |t|
        @database.find_table(t).full_table!
      end
    end

    def initialize
      @scramblers = []
      @page_counts = {}
      @database = Database.new(self)
      @filter = Filter.new
      @verbose = true
      $stdout.sync
    end

    def max_filtered_rows
      @max_filtered_rows || 2000
    end

    # FIXME: look at this API, passing a table name back seems wrong
    def sanitize_row(table_name, row)
      row = cleanup_types(row)
      scramble_row(table_name, row)
    end

    private

    def scramble_row(table_name, row)
      scramblers.each do |scrambler|
        row = scrambler.scramble(table_name, row)
      end
      row
    end

    def cleanup_types(row)
      row.map do |field|
        case field
        when Date, Time then field.to_s(:db)
        else
          field
        end
      end
    end
  end
end

require 'sqlite3'
require 'active_record'

module DbSubsetter
  # Manages exporting a subset of data
  class Exporter
    attr_writer :max_filtered_rows
    attr_reader :scramblers, :output, :database
    attr_accessor :filter, :verbose
    alias verbose? verbose

    # this is the batch size we insert into sqlite, which seems to be a reasonable balance of speed and memory usage
    INSERT_BATCH_SIZE = 250
    SELECT_BATCH_SIZE = 5000

    def export(filename)
      unless @database.exportable?
        if verbose?
          STDERR.puts "\nExportability issues:\n"
          @database.exportability_issues.each do |table, issues|
            STDERR.puts table
            issues.each { |issue| STDERR.puts "\t#{issue}" }
          end
        end
        raise ArgumentError, 'Database is not exportable as filtered!'
      end

      puts "Exporting data...\n\n" if @verbose
      @output = SQLite3::Database.new(filename)
      @output.execute 'CREATE TABLE tables (name TEXT, records_exported INTEGER, columns TEXT)'
      @database.exported_tables.each(&:export)
    end

    def add_scrambler(scrambler)
      @scramblers << scrambler
    end

    def ignore_tables(ignored)
      limit_tables('ignore!', ignored)
    end

    def subset_full_tables(full_tables)
      limit_tables('subset_in_full!', full_tables)
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
      row = TypeHelper.cleanup_types(row)
      scramble_row(table_name, row)
    end

    private

    def scramble_row(table_name, row)
      scramblers.each do |scrambler|
        row = scrambler.scramble(table_name, row)
      end
      row
    end

    def limit_tables(operation, apply_to)
      if apply_to.is_a?(Array)
        apply_to.each do |t|
          @database.find_table(t).send(operation)
        end
      elsif apply_to.is_a?(Symbol) || apply_to.is_a?(String)
        @database.find_table(apply_to).send(operation)
      elsif apply_to.is_a?(Regexp)
        @database.tables.each do |table|
          table.send(operation) if table.name =~ apply_to
        end
      else
        raise ArgumentError, "Don't know how to #{operation} a #{apply_to.class}"
      end
    end
  end
end

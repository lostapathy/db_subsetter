require 'sqlite3'
require 'active_record'

module DbSubsetter
  class Exporter
    attr_writer :filter, :max_unfiltered_rows, :max_filtered_rows

    def all_tables
      ActiveRecord::Base.connection.tables
    end

    def tables
      filter.tables
    end

    def total_row_counts
      tables.each.map do |table|
        query = Arel::Table.new(table, ActiveRecord::Base).project("count(1) AS num_rows")
        rows = ActiveRecord::Base.connection.select_one(query.to_sql)["num_rows"]
        {table => rows}
      end
    end

    def filtered_row_counts
      tables.each.map do |table|
        {table => filtered_row_count(table)}
      end
    end

    def verify_exportability(verbose = true)
      puts "Verifying table exportability ...\n\n" if verbose
      errors = tables.map{|x| verify_table_exportability(x) }.flatten.compact
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
        export_table(table)
      end
    end

    def add_scrambler(scrambler)
      @scramblers << scrambler
    end

    def initialize
      @scramblers = []
      @page_counts = {}
    end

    private
    def max_unfiltered_rows
      @max_unfiltered_rows || 1000
    end

    def max_filtered_rows
      @max_filtered_rows || 2000
    end

    # this is the batch size we insert into sqlite, which seems to be a reasonable balance of speed and memory usage
    def insert_batch_size
      250
    end

    def select_batch_size
      insert_batch_size * 20
    end

    def filter
      @filter ||= Filter.new
      @filter.exporter = self
      @filter
    end

    def filtered_row_count(table)
      query = Arel::Table.new(table, ActiveRecord::Base)
      query = filter.filter(table, query).project( Arel.sql("count(1)") )
      ActiveRecord::Base.connection.select_one(query.to_sql).values.first
    end

    def pages(table)
      @page_counts[table] ||= ( filtered_row_count(table) / select_batch_size.to_f ).ceil
    end

    def order_by(table)
      #TODO should probably allow the user to override this and manually set a sort order?
      key = ActiveRecord::Base.connection.primary_key(table)
      key || false
    end

    def verify_table_exportability(table)
      puts "Verifying: #{table}" if @verbose
      errors = []
      errors << "ERROR: Multiple pages but no primary key on: #{table}" if pages(table) > 1 && order_by(table).blank?
      errors << "ERROR: Too many rows in: #{table} (#{filtered_row_count(table)})" if( filtered_row_count(table) > max_filtered_rows )
      errors
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

    def scramble_data(table, data)
      @scramblers.each do |scrambler|
        data = scrambler.scramble(table, data)
      end
      data
    end

    def export_table(table)
      print "Exporting: #{table} (#{pages(table)} pages)" if @verbose
      $stdout.flush if @verbose
      columns = ActiveRecord::Base.connection.columns(table).map{ |table| table.name }
      rows_exported = 0
      @output.execute("CREATE TABLE #{table.underscore} ( data TEXT )")
      for i in 0..(pages(table) - 1)
        arel_table = query = Arel::Table.new(table, ActiveRecord::Base)
        query = filter.filter(table, query)
        # Need to extend this to take more than the first batch_size records
        query = query.order(arel_table[order_by(table)]) if order_by(table)


        query = query.skip(i * select_batch_size).take(select_batch_size) if pages(table) > 1
        sql = query.project( Arel.sql('*') ).to_sql

        records = ActiveRecord::Base.connection.select_rows( sql )
        records.each_slice(insert_batch_size) do |rows|
          @output.execute("INSERT INTO #{table.underscore} (data) VALUES #{ Array.new(rows.size){"(?)"}.join(",")}", rows.map{|x| scramble_data(table, cleanup_types(x))}.map(&:to_json) )
          rows_exported += rows.size
        end
        print "." if @verbose
        $stdout.flush if @verbose
      end
      puts "" if @verbose
      @output.execute("INSERT INTO tables VALUES (?, ?, ?)", [table, rows_exported, columns.to_json])
    end
  end
end


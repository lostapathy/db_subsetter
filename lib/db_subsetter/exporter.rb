require 'sqlite3'

module DbSubsetter
  class Exporter
    attr_writer :filter

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

    def verify_exportability
      tables.each do |table|
        verify_table_exportability(table)
      end
    end

    def export(filename)
      @output = SQLite3::Database.new(filename)

      tables.each do |table|
        export_table(table)
      end
    end



    private
    def max_rows
      10000000
    end

    def insert_batch_size
      250
    end

    def select_batch_size
      insert_batch_size
    end

    def filter
      @filter ||= Filter.new
      @filter.exporter = self
      @filter
    end

    def filtered_row_count(table)
      query = Arel::Table.new(table, ActiveRecord::Base).project( Arel.sql("count(1)") )
      query = filter.filter(table, query)
      ActiveRecord::Base.connection.select_one(query.to_sql).values.first
    end

    def pages(table)
      ( filtered_row_count(table) / select_batch_size.to_f ).ceil
    end

    def order_by(table)
      #TODO should probably allow the user to override this and manually set a sort order?
      key = ActiveRecord::Base.connection.primary_key(table)
      key || false
    end

    def verify_table_exportability(table)
      raise "ERROR: Multiple pages but no primary key on: #{table}" if pages(table) > 1 && order_by(table).blank?
      raise "ERROR: Too many rows in: #{table} (#{filtered_row_count(table)})" if( filtered_row_count(table) > max_rows )
    end

    def export_table(table)
      verify_table_exportability(table)

      @output.execute("create table #{table.underscore} ( data TEXT )")

      query = Arel::Table.new(table, ActiveRecord::Base)
      # Need to extend this to take more than the first batch_size records
      query = query.order(query[order_by(table)]) if order_by(table)

      sql = query.take(select_batch_size).project( Arel.sql('*') ).to_sql

      records = ActiveRecord::Base.connection.select_all( sql )
      records = records.to_a
      if records.size > 0
        @output.execute("INSERT INTO #{table.underscore} (data) VALUES #{ Array.new(records.size){"(?)"}.join(",")}", records.map(&:to_json) )
      end
    end

  end
end


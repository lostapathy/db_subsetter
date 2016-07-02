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
      verify_exportability

      @output = SQLite3::Database.new(filename)
      @output.execute("CREATE TABLE tables (name TEXT, columns TEXT)")
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
      insert_batch_size * 20
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

    def cleanup_types(row)
      row.map do |field|
        case field
        when Date, Time then field.to_s(:db)
        else
          field
        end
      end
    end

    def export_table(table)
      columns = ActiveRecord::Base.connection.columns(table).map{ |table| table.name }
      @output.execute("INSERT INTO tables VALUES (?, ?)", [table, columns.to_json])
      @output.execute("CREATE TABLE #{table.underscore} ( data TEXT )")
      for i in 0..pages(table)
        query = Arel::Table.new(table, ActiveRecord::Base)
        # Need to extend this to take more than the first batch_size records
        query = query.order(query[order_by(table)]) if order_by(table)

        sql = query.skip(i * select_batch_size).take(select_batch_size).project( Arel.sql('*') ).to_sql

        records = ActiveRecord::Base.connection.select_rows( sql )
        records.each_slice(insert_batch_size) do |rows|
          @output.execute("INSERT INTO #{table.underscore} (data) VALUES #{ Array.new(rows.size){"(?)"}.join(",")}", rows.map{|x| cleanup_types(x)}.map(&:to_json) )
        end
      end
    end

  end
end


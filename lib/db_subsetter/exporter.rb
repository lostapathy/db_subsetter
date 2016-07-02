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

    def batch_size
      100
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

    def export_table(table)
      @output.execute("create table #{table.underscore} ( data TEXT )")
      raise "too many rows in #{table}" if( filtered_row_count(table) > max_rows )

      query = Arel::Table.new(table, ActiveRecord::Base).project( Arel.sql('*') )

      # Need to extend this to take more than the first batch_size records
      records = ActiveRecord::Base.connection.select_all(query.take(batch_size).to_sql)
      #records.each do |row|
      records = records.to_a
      if records.size > 0
          @output.execute("INSERT INTO #{table.underscore} (data) VALUES #{ Array.new(records.size){"(?)"}.join(",")}", records.map(&:to_json) )
      end
        #raise "#{row.to_json}"
      #end
    end

  end
end


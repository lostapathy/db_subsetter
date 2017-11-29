module DbSubsetter
  class Table
    attr_accessor :name

    def initialize(name, exporter: nil)
      @name = name
      @exporter = exporter
    end

    def filtered_row_count(filter)
      query = Arel::Table.new(@name)
      query = filter.filter(self, query)
      query = query.project( Arel.sql("count(1)") )
      ActiveRecord::Base.connection.select_one(query.to_sql).values.first
    end

    def pages(filter)
      @page_count ||= ( filtered_row_count(filter) / @exporter.select_batch_size.to_f ).ceil
    end


    def export(filter, verbose: true)
      if verbose
        print "Exporting: #{@name} (#{pages(filter)} pages)"
        $stdout.flush
      end

      rows_exported = 0
      @exporter.output.execute("CREATE TABLE #{@name.underscore} ( data TEXT )")
      for i in 0..(pages(filter) - 1)
        arel_table = query = Arel::Table.new(@name)
        query = filter.filter(self, query)
        # Need to extend this to take more than the first batch_size records
        query = query.order(arel_table[order_by]) if order_by

        query = query.skip(i * select_batch_size).take(select_batch_size) if pages(filter) > 1
        sql = query.project( Arel.sql('*') ).to_sql

        records = ActiveRecord::Base.connection.select_rows( sql )
        records.each_slice(@exporter.insert_batch_size) do |rows|
          @exporter.output.execute("INSERT INTO #{@name.underscore} (data) VALUES #{ Array.new(rows.size){"(?)"}.join(",")}", rows.map{|x| scramble_data(cleanup_types(x))}.map(&:to_json) )
          rows_exported += rows.size
        end

        if verbose
          print '.'
          $stdout.flush
        end
      end
      puts "" if verbose
      columns = ActiveRecord::Base.connection.columns(@name).map{ |column| column.name }
      @exporter.output.execute("INSERT INTO tables VALUES (?, ?, ?)", [@name, rows_exported, columns.to_json])
    end

    def order_by
      #TODO should probably allow the user to override this and manually set a sort order?
      key = ActiveRecord::Base.connection.primary_key(@name)
      key || false
    end

    private

    def scramble_data(data)
      @exporter.scramblers.each do |scrambler|
        data = scrambler.scramble(@name, data)
      end
      data
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

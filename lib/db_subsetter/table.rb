module DbSubsetter
  class Table
    attr_accessor :name

    def initialize(name, exporter: nil)
      @name = name
      @exporter = exporter
    end

    def total_row_count
      query = Arel::Table.new(table, ActiveRecord::Base).project('count(1) AS num_rows')
      ActiveRecord::Base.connection.select_one(query.to_sql)['num_rows']
    end

    def filtered_row_count
      query = Arel::Table.new(@name)
      query = @exporter.filter.filter(self, query)
      query = query.project( Arel.sql('count(1)') )
      ActiveRecord::Base.connection.select_one(query.to_sql).values.first
    end

    def pages
      @page_count ||= ( filtered_row_count / @exporter.select_batch_size.to_f ).ceil
    end

    def export(verbose: true)
      if verbose
        print "Exporting: #{@name} (#{pages} pages)"
        $stdout.flush
      end

      rows_exported = 0
      @exporter.output.execute("CREATE TABLE #{@name.underscore} ( data TEXT )")
      (0..(pages - 1)).each do |i|
        records_for_page(i).each_slice(@exporter.insert_batch_size) do |rows|
          @exporter.output.execute("INSERT INTO #{@name.underscore} (data) VALUES #{ Array.new(rows.size) { '(?)' }.join(',')}", rows.map { |x| scramble_data(cleanup_types(x)) }.map(&:to_json) )
          rows_exported += rows.size
        end

        if verbose
          print '.'
          $stdout.flush
        end
      end
      puts '' if verbose
      columns = ActiveRecord::Base.connection.columns(@name).map { |column| column.name }
      @exporter.output.execute('INSERT INTO tables VALUES (?, ?, ?)', [@name, rows_exported, columns.to_json])
    end

    def order_by
      # TODO should probably allow the user to override this and manually set a sort order?
      key = ActiveRecord::Base.connection.primary_key(@name)
      key || false
    end

    def can_export?(verbose: true)
      puts "Verifying: #{@name}" if verbose
      errors = []
      errors << "ERROR: Multiple pages but no primary key on: #{@name}" if pages > 1 && order_by.blank?
      errors << "ERROR: Too many rows in: #{@name} (#{filtered_row_count})" if( filtered_row_count > @exporter.max_filtered_rows )
      errors
    end

    private

    def records_for_page(page)
      arel_table = query = Arel::Table.new(@name)
      query = @exporter.filter.filter(self, query)
      query = query.order(arel_table[order_by]) if order_by

      query = query.skip(page * select_batch_size).take(select_batch_size) if pages > 1
      sql = query.project( Arel.sql('*') ).to_sql

      ActiveRecord::Base.connection.select_rows(sql)
    end

    def scramble_data(row)
      @exporter.scramblers.each do |scrambler|
        row = scrambler.scramble(@name, row)
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

module DbSubsetter
  class Table
    attr_accessor :name

    def initialize(name, exporter: nil)
      @name = name
      @exporter = exporter
      @loaded_ids = false
    end

    def total_row_count
      query = Arel::Table.new(@name).project('count(1) AS num_rows')
      ActiveRecord::Base.connection.select_one(query.to_sql)['num_rows']
    end

    def filtered_row_count
      query = Arel::Table.new(@name)
      query = @exporter.filter.filter(self, query)
      query = query.project( Arel.sql('count(1) as num_rows') )
      ActiveRecord::Base.connection.select_one(query.to_sql)['num_rows']
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

    def primary_key
      ActiveRecord::Base.connection.primary_key(@name)
    end

    def can_export?(verbose: true)
      puts "Verifying: #{@name}" if verbose

      errors = []

      begin
        errors << "ERROR: Multiple pages but no primary key on: #{@name}" if pages > 1 && primary_key.blank?
        errors << "ERROR: Too many rows in: #{@name} (#{filtered_row_count})" if( filtered_row_count > @exporter.max_filtered_rows )
      rescue CircularRelationError
        errors << "ERROR: Circular relations through: #{@name}"
      end

      errors
    end

    def foreign_keys?
      filterable_relations.count > 0
    end

    def filterable_relations
      # FIXME: need to remove those relations we can't filter on - things that don't point to a PK
      ActiveRecord::Base.connection.foreign_keys(@name).map { |x| Relation.new(x, @exporter) }
    end

    def filtered_ids
      return @id_cache if @id_cache

      raise CircularRelationError.new("Circular relations through: #{@name}!") if @loaded_ids

      @loaded_ids = true

      query = Arel::Table.new(@name)
      sql = @exporter.filter.filter(self, query).project(:id).to_sql

      data = ActiveRecord::Base.connection.select_rows(sql).flatten
      data << nil
      @id_cache = data
    end

    def filter_foreign_keys(query)
      filterable_relations.each do |relation|
        other_table = relation.to_table
        key = relation.column.to_sym

        other_ids = other_table.filtered_ids
        query = query.where(arel_table[key].in(other_ids).or(arel_table[key].eq(nil)))
      end
      query
    end

    private

    def records_for_page(page)
      query = @exporter.filter.filter(self, arel_table)
      query = query.order(arel_table[primary_key]) if primary_key

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

    def arel_table
      @arel_table ||= Arel::Table.new(@name)
    end
  end
end

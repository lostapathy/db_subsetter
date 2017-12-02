module DbSubsetter
  class Table
    attr_accessor :name, :ignore

    def initialize(name, database, exporter)
      @name = name
      @exporter = exporter
      @loaded_ids = false
      @database = database
      @ignored = false
    end

    def ignore!
      @ignored = true
    end

    def ignored?
      @ignored
    end

    def total_row_count
      query = arel_table.project('count(1) AS num_rows')
      ActiveRecord::Base.connection.select_one(query.to_sql)['num_rows']
    end

    def filtered_row_count
      query = filtered_records.project(Arel.sql('count(1) AS num_rows'))
      ActiveRecord::Base.connection.select_one(query.to_sql)['num_rows']
    end

    def pages
      @page_count ||= (filtered_row_count / Exporter::SELECT_BATCH_SIZE.to_f).ceil
    end

    def export(verbose: true)
      if verbose
        print "Exporting: #{@name} (#{pages} pages)"
        $stdout.flush
      end

      rows_exported = 0
      @exporter.output.execute("CREATE TABLE #{@name.underscore} ( data TEXT )")
      (0..(pages - 1)).each do |i|
        records_for_page(i).each_slice(Exporter::INSERT_BATCH_SIZE) do |rows|
          @exporter.output.execute("INSERT INTO #{@name.underscore} (data) VALUES #{Array.new(rows.size) { '(?)' }.join(',')}", rows.map { |x| scramble_data(cleanup_types(x)) }.map(&:to_json))
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
      puts "Verifying: #{@name} (#{filtered_row_count}/#{total_row_count})" if verbose
      errors = []
      begin
        errors << "ERROR: Multiple pages but no primary key on: #{@name}" if pages > 1 && primary_key.blank?
        errors << "ERROR: Too many rows in: #{@name} (#{filtered_row_count})" if(filtered_row_count > @exporter.max_filtered_rows)
      rescue CircularRelationError
        errors << "ERROR: Circular relations through: #{@name}"
      end
      errors
    end

    def relations
      ActiveRecord::Base.connection.foreign_keys(@name).map { |x| Relation.new(x, @database) }
    end

    def filtered_ids
      return @id_cache if @id_cache

      raise CircularRelationError.new("Circular relations through: #{@name}!") if @loaded_ids

      @loaded_ids = true

      sql = filtered_records.project(:id).to_sql

      data = ActiveRecord::Base.connection.select_rows(sql).flatten
      data << nil
      @id_cache = data
    end

    def filter_foreign_keys(query)
      relations.each do |relation|
        next unless relation.can_subset_from?
        other_table = relation.to_table
        key = relation.column.to_sym

        other_ids = other_table.filtered_ids
        query = query.where(arel_table[key].in(other_ids).or(arel_table[key].eq(nil)))
      end
      query
    end

    private

    def filtered_records
      query = @exporter.filter.apply(self, arel_table)

      if total_row_count > 2000
        # FIXME: need a mechanism to export everything regardless (i.e., table of states/countries)
        # perhaps only try to explore foreign_keys if > 1 pages?
        # FIXME: need a way to opt-out of auto-filters, or at least auto-filters on some keys
        query = filter_foreign_keys(query)
      end
      query
    end

    def records_for_page(page)
      query = filtered_records
      query = query.order(arel_table[primary_key]) if primary_key

      query = query.skip(page * Exporter::SELECT_BATCH_SIZE).take(Exporter::SELECT_BATCH_SIZE) if pages > 1
      sql = query.project(Arel.sql('*')).to_sql

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

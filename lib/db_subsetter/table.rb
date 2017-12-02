module DbSubsetter
  # A database in the database to be subset or imported
  class Table
    attr_accessor :name

    def initialize(name, database, exporter)
      @name = name
      @exporter = exporter
      @database = database
    end

    # FIXME: these 4 methods don't feel quite like the correct API yet
    def ignore!
      @ignored = true
    end

    def full_table!
      @full_table = true
    end

    def full_table?
      @full_table
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

    # FIXME: move the raw SQL into another class
    def export(verbose: true)
      print "Exporting: #{@name} (#{pages} pages)" if verbose

      rows_exported = 0
      @exporter.output.execute("CREATE TABLE #{@name.underscore} ( data TEXT )")
      0.upto(pages - 1).each do |page|
        records_for_page(page).each_slice(Exporter::INSERT_BATCH_SIZE) do |rows|
          data = rows.map { |x| scramble_data(cleanup_types(x)) }.map(&:to_json)

          @exporter.output.execute("INSERT INTO #{@name.underscore} (data) VALUES #{Array.new(rows.size) { '(?)' }.join(',')}", data)
          rows_exported += rows.size
        end

        print '.' if verbose
      end
      puts '' if verbose
      columns = ActiveRecord::Base.connection.columns(@name).map(&:name)
      @exporter.output.execute('INSERT INTO tables VALUES (?, ?, ?)', [@name, rows_exported, columns.to_json])
    end

    def exportable?(verbose: true)
      errors = []
      begin
        puts "Verifying: #{@name} (#{filtered_row_count}/#{total_row_count})" if verbose
        errors << "ERROR: Multiple pages but no primary key on: #{@name}" if pages > 1 && primary_key.blank?
        errors << "ERROR: Too many rows in: #{@name} (#{filtered_row_count})" if filtered_row_count > @exporter.max_filtered_rows
      rescue CircularRelationError
        errors << "ERROR: Circular relations through: #{@name}"
      end
    end

    def filtered_ids
      return @id_cache if @id_cache

      raise CircularRelationError if @loaded_ids
      @loaded_ids = true

      sql = filtered_records.project(:id).to_sql

      @id_cache = ActiveRecord::Base.connection.select_rows(sql).flatten
    end

    def arel_table
      @arel_table ||= Arel::Table.new(@name)
    end

    private

    def relations
      ActiveRecord::Base.connection.foreign_keys(@name).map { |x| Relation.new(x, @database) }
    end

    def primary_key
      ActiveRecord::Base.connection.primary_key(@name)
    end

    def filtered_records
      query = @exporter.filter.apply(self, arel_table)

      if total_row_count > @exporter.max_filtered_rows
        query = filter_foreign_keys(query)
      end
      query
    end

    def filter_foreign_keys(query)
      relations.each do |relation|
        query = relation.apply_subset(query)
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

    # FIXME: this logic doesn't belong here
    def scramble_data(row)
      @exporter.scramble_row(@name, row)
    end

    # FIXME: this method doesn't belong here
    def cleanup_types(row)
      row.map do |field|
        case field
        when Date, Time then field.to_s(:db)
        else
          field
        end
      end
    end

    def pages
      @page_count ||= (filtered_row_count / Exporter::SELECT_BATCH_SIZE.to_f).ceil
    end
  end
end

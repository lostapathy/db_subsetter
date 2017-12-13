module DbSubsetter
  # A database in the database to be subset or imported
  class Table
    attr_accessor :name

    def initialize(name, database, exporter)
      @name = name
      @exporter = exporter
      @database = database
      @exportability_issues = @id_cache = @subset_in_full = @loaded_ids = @full_table = @ignored = false
    end

    # FIXME: these 4 methods don't feel quite like the correct API yet
    def ignore!
      @ignored = true
    end

    def subset_in_full!
      @subset_in_full = true
    end

    def subset_in_full?
      @subset_in_full
    end

    def ignored?
      @ignored
    end

    def total_row_count
      query = arel_table.project('count(1) AS num_rows')
      ActiveRecord::Base.connection.select_one(query.to_sql)['num_rows'].to_i # rails-4.2+pg needs to_i
    end

    def filtered_row_count
      query = filtered_records.project(Arel.sql('count(1) AS num_rows'))
      ActiveRecord::Base.connection.select_one(query.to_sql)['num_rows'].to_i # rails-4.2+pg needs to_i
    end

    # FIXME: move the raw SQL into another class
    def export
      print "Exporting: #{@name} (#{pages} pages)" if verbose

      rows_exported = 0
      @exporter.output.execute("CREATE TABLE #{@name.underscore} ( data TEXT )")
      0.upto(pages - 1).each do |page|
        records_for_page(page).each_slice(Exporter::INSERT_BATCH_SIZE) do |rows|
          data = rows.map { |x| @exporter.sanitize_row(@name, x) }.map(&:to_json)

          @exporter.output.execute("INSERT INTO #{@name.underscore} (data) VALUES #{Array.new(rows.size) { '(?)' }.join(',')}", data)
          rows_exported += rows.size
        end

        print '.' if verbose
      end
      puts '' if verbose
      columns = ActiveRecord::Base.connection.columns(@name).map(&:name)
      @exporter.output.execute('INSERT INTO tables VALUES (?, ?, ?)', [@name, rows_exported, columns.to_json])
    end

    def exportable?
      exportability_issues.empty?
    end

    def exportability_issues
      return @exportability_issues if @exportability_issues

      @exportability_issues = []
      begin
        puts "Verifying: #{@name} (#{filtered_row_count}/#{total_row_count})" if verbose
        @exportability_issues << 'Multiple pages but no primary key' if pages > 1 && primary_key.blank?
        @exportability_issues << "Too many rows (#{filtered_row_count})" if filtered_row_count > @exporter.max_filtered_rows
      rescue CircularRelationError
        @exportability_issues << 'Circular relations through this table'
      end
      @exportability_issues
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

    def primary_key
      ActiveRecord::Base.connection.primary_key(@name)
    end

    def relations
      ActiveRecord::Base.connection.foreign_keys(@name).map { |x| Relation.new(x, @database) }
    end

    private

    def verbose
      @exporter.verbose?
    end

    def filtered_records
      return arel_table if @exporter.nil? || @exporter.filter.nil?
      query = @exporter.filter.apply(self, arel_table)

      query = filter_foreign_keys(query) if total_row_count > @exporter.max_filtered_rows
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

    def pages
      @page_count ||= (filtered_row_count / Exporter::SELECT_BATCH_SIZE.to_f).ceil
    end
  end
end

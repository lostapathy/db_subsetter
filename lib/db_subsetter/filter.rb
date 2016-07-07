module DbSubsetter
  class Filter
    attr_writer :exporter

    def ignore_tables
      []
    end

    def tables
      @exporter.all_tables - ActiveRecord::SchemaDumper.ignore_tables - ignore_tables
    end

    def filter(table, query)
      filter_method = "filter_#{table.downcase}"
      if self.respond_to? filter_method
        self.send(filter_method, query)
      else
        query
      end
    end

  end
end


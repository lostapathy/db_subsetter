require 'active_record'

module DbSubsetter
  class Filter
    attr_writer :exporter

    def ignore_tables
      []
    end

    def tables
      table_list = @exporter.all_tables - ActiveRecord::SchemaDumper.ignore_tables - ignore_tables

      table_list.map { |table_name| Table.new(table_name)}
    end

    def filter(table, query)
      filter_method = "filter_#{table.name.downcase}"
      if self.respond_to? filter_method
        self.send(filter_method, query)
      else
        query
      end
    end

  end
end


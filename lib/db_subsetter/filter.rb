require 'active_record'

module DbSubsetter
  class Filter
    attr_writer :exporter

    def ignore_tables
      []
    end

    def filter(table, query)
      filter_method = "filter_#{table.name.downcase}"
      if respond_to? filter_method
        send(filter_method, query)
      else
        query
      end
    end
  end
end


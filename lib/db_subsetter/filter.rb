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
      elsif table.foreign_keys? && table.total_row_count > 500
        # FIXME: need a mechanism to export everything regardless (i.e., table of states/countries)
        # perhaps only try to explore foreign_keys if > 1 pages?
        # FIXME: need a way to opt-out of auto-filters, or at least auto-filters on some keys
        table.filter_foreign_keys(query)
      else
        query
      end
    end
  end
end


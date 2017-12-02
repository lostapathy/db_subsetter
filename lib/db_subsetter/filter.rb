require 'active_record'

module DbSubsetter
  class Filter
    def ignore_tables
      []
    end

    # FIXME: this method probably belongs in Table
    def filter(table, query)
      filter_method = "filter_#{table.name.downcase}"
      if respond_to? filter_method
        send(filter_method, query)
      elsif table.total_row_count > 2000
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


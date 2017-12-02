require 'active_record'

module DbSubsetter
  class Filter
    def apply(table, query)
      filter_method = "filter_#{table.name.downcase}"
      if respond_to? filter_method
        send(filter_method, query)
      else
        query
      end
    end
  end
end

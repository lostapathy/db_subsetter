require 'active_record'

module DbSubsetter
  # Base class for defining a custom filter for defining how to create a subset
  # of your database
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

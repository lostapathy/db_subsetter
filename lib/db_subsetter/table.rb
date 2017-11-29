module DbSubsetter
  class Table
    attr_accessor :name

    def initialize(name)
      @name = name
    end

    def filtered_row_count(filter)
      query = Arel::Table.new(@name)
      query = filter.filter(self, query)
      query = query.project( Arel.sql("count(1)") )
      ActiveRecord::Base.connection.select_one(query.to_sql).values.first
    end

    # FIXME: this is just for compat while I extract this
    def to_s
      @name
    end
  end
end

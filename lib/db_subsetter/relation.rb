module DbSubsetter
  # Wraps a foreign key relationship between two tables
  class Relation
    attr_reader :to_table, :column

    def initialize(ar_association, database)
      @column = ar_association.column
      @to_table = database.find_table ar_association.to_table
    end
  end
end

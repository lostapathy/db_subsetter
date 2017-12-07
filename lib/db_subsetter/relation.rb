module DbSubsetter
  # Wraps a foreign key relationship between two tables
  class Relation
    attr_reader :to_table, :column

    def initialize(ar_association, database)
      @column = ar_association.column
      @other_column = ar_association.primary_key
      @to_table = database.find_table ar_association.to_table
      @from_table = database.find_table ar_association.from_table
    end

    # We cannot subset automatically if the relation points to a non-primary key
    def can_subset_from?
      @to_table.primary_key == @other_column
    end

    def apply_subset(query)
      return query if !can_subset_from? || @to_table.subset_in_full?

      # If the other table is ignored, we must not include any records that reference it
      query = query.where(arel_table[@column].neq(nil)) if @to_table.ignored?

      # If a related table will be exported in full, don't bother subsetting on that key
      unless @to_table.subset_in_full?
        other_ids = @to_table.filtered_ids
        arel_table = @from_table.arel_table
        conditions = arel_table[@column].in(other_ids).or(arel_table[@column].eq(nil))
        query = query.where(conditions)
      end
      query
    end
  end
end

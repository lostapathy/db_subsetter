module DbSubsetter
  # Wraps a foreign key relationship between two tables
  class Relation
    attr_reader :to_table, :column

    def initialize(ar_association, database)
      @column = ar_association.column
      @to_table = database.find_table ar_association.to_table
      @from_table = database.find_table ar_association.from_table
    end

    def can_subset_from?
      # FIXME: make this reject keys that don't point back at primary key
      true
    end

    def apply_subset(query)
      # FIXME: if a relation points back to an ignored table, make sure that key is nil
      # to preserve referential integrity.  Potentially provide option to not filter, but
      # nil out that key?
      return query if !can_subset_from? || @to_table.full_table?

      # FIXME: if a related table will be exported in full, don't bother subsetting on that key

      other_ids = @to_table.filtered_ids
      arel_table = @from_table.arel_table
      conditions = arel_table[@column].in(other_ids).or(arel_table[@column].eq(nil))
      query.where(conditions)
    end
  end
end

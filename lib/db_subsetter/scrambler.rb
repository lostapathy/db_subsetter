require 'random-word'

module DbSubsetter
  class Scrambler
    def scramble(table, row)
      scramble_method = "scramble_#{table.downcase}"
      if self.respond_to? scramble_method
        self.send(scramble_method, row)
      else
        row
      end
    end

    def initialize
      @column_index_cache = {}
    end

    protected
    def scramble_column(table, column, row_data, value)
      row_data[column_index(table, column)] = value
    end

    private
    def column_index(table, column)
      @column_index_cache["#{table}##{column}"] ||= ActiveRecord::Base.connection.columns(table).map{|c| c.name}.index(column.to_s)
    end
  end
end

require 'test_helper'

class FilterTest < DbSubsetter::Test
  def test_without_custom_filter
    filter = DbSubsetter::Filter.new
    query = :whatever

    Struct.new('Table', :name)
    table = Struct::Table.new('whatever')
    assert_equal query, filter.apply(table, query)
  end
end

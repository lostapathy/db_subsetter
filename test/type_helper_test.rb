require 'test_helper'

class TypeHelperTest < DbSubsetter::Test
  def test_leaves_string_symbol_numbers_alone
    input = ['foo', :bar, 42]
    assert_equal input, DbSubsetter::TypeHelper.cleanup_types(input)
  end

  def test_translates_dates_to_strings
    input = [Date.parse('2017-01-01')]
    output = ['2017-01-01']
    assert_equal output, DbSubsetter::TypeHelper.cleanup_types(input)
  end
end

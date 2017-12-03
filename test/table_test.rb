require 'test_helper'

class TableTest < DbSubsetter::Test
  def test_total_row_count
    setup_db
    assert_equal 0, @db.tables.first.total_row_count
  end
end

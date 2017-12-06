require 'test_helper'

class DatabaseTest < DbSubsetter::Test
  def test_table_count
    setup_db
    assert_equal 2, @db.tables.size
  end

  def test_find_table_works
    setup_db
    assert_equal 'posts', @db.find_table('posts').name
  end

  def test_find_table_by_symbol
    setup_db
    assert_equal 'posts', @db.find_table(:posts).name
  end

  def test_exported_tables
    setup_db
    assert_equal 2, @db.exported_tables.size
  end
end

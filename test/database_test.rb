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

  def test_total_row_counts
    post_count = 42
    post_count.times do
      Post.create(title: 'test')
    end

    author_count = 4100
    author_count.times do
      Author.create(name: 'test')
    end
    setup_db
    assert_equal({ 'posts' => post_count, 'authors' => author_count }, @db.total_row_counts)
  end
end

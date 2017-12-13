require 'test_helper'

class FilterTest < DbSubsetter::Test
  def test_without_custom_filter
    filter = DbSubsetter::Filter.new
    query = :whatever

    Struct.new('Table', :name)
    table = Struct::Table.new('whatever')
    assert_equal query, filter.apply(table, query)
  end

  def test_custom_filter_empty_result
    filter = TestEmptyFilter.new
    post_count = 42
    post_count.times do
      Post.create(title: 'junk')
    end
    setup_db
    @exporter.filter = filter

    assert_equal post_count, @db.find_table(:posts).total_row_count
    assert_equal 0, @db.find_table(:posts).filtered_row_count
  end

  def test_custom_filter_with_subset
    filter = TestSubsetFilter.new
    post_count = 42
    post_count.times do
      Post.create(title: 'junk')
    end
    setup_db
    @exporter.filter = filter

    assert_equal post_count, @db.find_table(:posts).total_row_count
    assert_equal 10, @db.find_table(:posts).filtered_row_count
  end
  class TestEmptyFilter < DbSubsetter::Filter
    def filter_posts(query)
      query.where(query[:id].in(nil))
    end
  end

  class TestSubsetFilter < DbSubsetter::Filter
    def filter_posts(query)
      query.where(query[:id].between(1..10))
    end
  end
end

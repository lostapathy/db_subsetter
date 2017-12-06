require 'test_helper'

class Post < ActiveRecord::Base
end

class TableTest < DbSubsetter::Test
  def test_total_row_count
    setup_db
    assert_equal 0, @db.tables.first.total_row_count
  end

  def test_filtered_row_count_without_keys
    setup_db
    assert_equal 0, @db.find_table('posts').filtered_row_count
  end

  def test_filtered_row_count_with_data
    post_count = 1000
    post_count.times do
      Post.create(title: 'test')
    end
    setup_db
    assert_equal post_count, @db.find_table('posts').filtered_row_count
  end

  def test_primary_key
    setup_db
    assert_equal 'id', @db.find_table('posts').primary_key
  end

  def test_no_relations_on_empty_db
    setup_db
    assert_equal 0, @db.find_table('posts').send(:relations).size
  end

  def test_finds_relation
    add_reference(:posts, :author)
    setup_db
    assert_equal 1, @db.find_table('posts').send(:relations).size
  end

  def test_circular_relation
    add_reference(:posts, :author)
    add_reference(:authors, :post)
    setup_db

    @db.find_table(:posts).exportable?
  end
end

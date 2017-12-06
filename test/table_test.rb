require 'test_helper'

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

  def test_no_circular_relation_on_empty_tables
    add_reference(:posts, :authors)
    add_reference(:authors, :posts)
    setup_db

    assert @db.find_table(:authors).exportable?
  ensure
    remove_foreign_key(:posts, :authors)
    remove_foreign_key(:authors, :posts)
  end

  def test_no_circular_relation_on_one_empty_tables
    add_reference(:posts, :authors)
    add_reference(:authors, :posts)
    setup_db

    # FIXME: base this on max records in exporter
    2500.times { Post.create!(title: 'test') }
    assert @db.find_table(:authors).exportable?
  ensure
    remove_foreign_key(:posts, :authors)
    remove_foreign_key(:authors, :posts)
  end

  def test_circular_relation_on_full_tables
    add_reference(:posts, :authors)
    add_reference(:authors, :posts)
    setup_db

    # FIXME: base this on max records in exporter
    2500.times { Post.create!(title: 'test') }
    2500.times { Author.create!(name: 'test') }
    assert !@db.find_table(:authors).exportable?
  ensure
    remove_foreign_key(:posts, :authors)
    remove_foreign_key(:authors, :posts)
  end
end

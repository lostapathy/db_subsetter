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
    add_reference(:posts, :authors)
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

    @exporter.max_filtered_rows = 20
    50.times { Post.create!(title: 'test') }
    assert @db.find_table(:authors).exportable?
  ensure
    remove_foreign_key(:posts, :authors)
    remove_foreign_key(:authors, :posts)
  end

  def test_circular_relation_on_full_tables
    add_reference(:posts, :authors)
    add_reference(:authors, :posts)
    setup_db

    @exporter.max_filtered_rows = 20

    50.times { Post.create!(title: 'test') }
    50.times { Author.create!(name: 'test') }
    assert !@db.find_table(:authors).exportable?
  ensure
    remove_foreign_key(:posts, :authors)
    remove_foreign_key(:authors, :posts)
  end

  class Get20Filter < DbSubsetter::Filter
    def filter_authors(query)
      query.where(query[:id].between(1..20))
    end
  end

  def test_filters_foreign_key
    add_reference(:posts, :authors)
    setup_db
    @exporter.filter = Get20Filter.new

    @exporter.max_filtered_rows = 20

    50.times do
      author = Author.create(name: 'whatever name')
      Post.create!(title: 'test', author_id: author.id)
    end
    assert_equal 20, @db.find_table(:authors).filtered_row_count
    assert_equal 20, @db.find_table(:posts).filtered_row_count
  ensure
    remove_foreign_key(:posts, :authors)
  end

  def test_cant_subset_without_primary_key
    ActiveRecord::Schema.define do
      create_table :bogus, force: true, id: false do |t|
        t.string :title, null: true
      end
    end

    (DbSubsetter::Exporter::SELECT_BATCH_SIZE + 10).times { Bogus.create!(title: 'bogus!') }
    setup_db
    @exporter.max_filtered_rows = DbSubsetter::Exporter::SELECT_BATCH_SIZE * 2

    assert !@db.find_table(:bogus).exportable?
  ensure
    ActiveRecord::Schema.define do
      drop_table :bogus
    end
  end

  def test_not_exportable_if_too_many_rows
    setup_db
    2500.times { Post.create!(title: 'test') }
    assert !@db.find_table(:posts).exportable?
  end

  def test_dont_subset_by_ignored_table
    skip
    # probably need more than one case here to cover only getting nil records etc
  end
end

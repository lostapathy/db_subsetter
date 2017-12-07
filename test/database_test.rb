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

    # FIXME: lower these limits by setting max_filtered_rows
    author_count = 4100
    author_count.times do
      Author.create(name: 'test')
    end
    setup_db
    assert_equal({ 'posts' => post_count, 'authors' => author_count }, @db.total_row_counts)
  end

  def test_empty_db_exportable
    setup_db

    assert @db.exportable?
    assert_equal({}, @db.exportability_issues)
  end

  def test_unfiltered_db_not_exportable
    11.times do
      Post.create(title: 'test')
    end
    setup_db
    @exporter.max_filtered_rows = 10
    assert !@db.exportable?

    assert_equal({ 'posts' => ['Too many rows (11)'] }, @db.exportability_issues)
  end

  def test_filtered_row_counts_when_unfiltered
    post_count = 42
    post_count.times do
      Post.create(title: 'test')
    end

    author_count = 100
    author_count.times do
      Author.create(name: 'test')
    end
    setup_db
    assert_equal({ 'posts' => post_count, 'authors' => author_count }, @db.filtered_row_counts)
  end
end

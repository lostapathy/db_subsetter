require 'test_helper'

class ExporterTest < DbSubsetter::Test
  def test_ignore_tables_with_array
    setup_db

    @exporter.ignore_tables [:posts]
    assert @db.find_table(:posts).ignored?
    assert !@db.find_table(:authors).ignored?
  end

  def test_ignore_tables_with_string
    setup_db

    @exporter.ignore_tables 'posts'
    assert @db.find_table(:posts).ignored?
    assert !@db.find_table(:authors).ignored?
  end

  def test_ignore_tables_with_symbol
    setup_db

    @exporter.ignore_tables :posts
    assert @db.find_table(:posts).ignored?
    assert !@db.find_table(:authors).ignored?
  end

  def test_ignore_tables_with_regex
    setup_db

    @exporter.ignore_tables(/post.*/)
    assert @db.find_table(:posts).ignored?
    assert !@db.find_table(:authors).ignored?
  end

  def test_ignore_tables_with_invalid
    setup_db
    assert_raises ArgumentError do
      @exporter.ignore_tables(42)
    end
  end

  def test_export_full_tables_with_array
    setup_db

    @exporter.subset_full_tables [:posts]
    assert @db.find_table(:posts).subset_in_full?
    assert !@db.find_table(:authors).subset_in_full?
  end

  def test_export_full_tables_with_string
    setup_db

    @exporter.subset_full_tables 'posts'
    assert @db.find_table(:posts).subset_in_full?
    assert !@db.find_table(:authors).subset_in_full?
  end

  def test_export_full_tables_with_symbol
    setup_db

    @exporter.subset_full_tables :posts
    assert @db.find_table(:posts).subset_in_full?
    assert !@db.find_table(:authors).subset_in_full?
  end

  def test_export_full_tables_with_regex
    setup_db

    @exporter.subset_full_tables(/post.*/)
    assert @db.find_table(:posts).subset_in_full?
    assert !@db.find_table(:authors).subset_in_full?
  end

  def test_override_max_filtered_rows
    skip
  end

  def test_max_filtered_rows_for_table
    skip
    # We want to be able to say only this table gets different than global limit
  end

  def test_sanitize_row_leaves_string_symbol_numbers_alone
    setup_db

    input = ['foo', :bar, 42]
    assert_equal input, @exporter.sanitize_row('whatever', input)
  end

  def test_export_fails_when_not_exportable
    post_count = 42
    post_count.times do
      Post.create!(title: 'test')
    end

    author_count = 100
    author_count.times do
      Author.create!(name: 'test')
    end
    setup_db
    @exporter.max_filtered_rows = 50
    @exporter.verbose = true
    assert !@db.exportable?
    assert_output(nil) do
      assert_raises(ArgumentError) { @exporter.export('test.sqlite3') }
    end
  ensure
    FileUtils.rm('test.sqlite3') if File.exist?('test.sqlite3')
  end

  def test_export_works_when_exportable
    post_count = 42
    post_count.times do
      Post.create!(title: 'test')
    end

    author_count = 100
    author_count.times do
      Author.create!(name: 'test')
    end
    setup_db
    assert @db.exportable?
    @exporter.export('test.sqlite3')
    # FIXME: need to add assertions
  ensure
    FileUtils.rm('test.sqlite3') if File.exist?('test.sqlite3')
  end
end

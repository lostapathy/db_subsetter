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
end

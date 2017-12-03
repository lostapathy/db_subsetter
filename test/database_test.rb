require 'test_helper'

class DatabaseTest < Minitest::Test
  def setup
    ActiveRecord::Base.establish_connection(DB_CONFIG)
  end

  def setup_db
    @db = DbSubsetter::Database.new(nil)
  end

  def teardown
    ActiveRecord::Base.connection_pool.disconnect!
  end

  def test_zero_tables_in_empty_db
    setup_db
    assert_equal 0, @db.tables.size
  end

  def test_table_count
    ActiveRecord::Schema.define do
      create_table :posts, force: true do |t|
      end
    end
    setup_db
    assert_equal 1, @db.tables.size

    ActiveRecord::Schema.define do
      drop_table :posts
    end
  end

  def test_find_table_works
    ActiveRecord::Schema.define do
      create_table :posts, force: true do |t|
      end
    end
    setup_db
    assert_equal 'posts', @db.find_table('posts').name
    ActiveRecord::Schema.define do
      drop_table :posts
    end
  end

  def test_exported_tables
    ActiveRecord::Schema.define do
      create_table :posts, force: true do |t|
      end
    end
    setup_db
    assert_equal 1, @db.exported_tables.size
    ActiveRecord::Schema.define do
      drop_table :posts
    end
  end
end

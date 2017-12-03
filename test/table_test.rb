require 'test_helper'

class TableTest < Minitest::Test
  def setup
    ActiveRecord::Base.establish_connection(DB_CONFIG)
  end

  def setup_db
    @db = DbSubsetter::Database.new(nil)
  end

  def teardown
    ActiveRecord::Base.connection_pool.disconnect!
  end

  def test_total_row_count
    ActiveRecord::Schema.define do
      create_table :posts, force: true do |t|
      end
    end
    setup_db
    assert_equal 0, @db.tables.first.total_row_count

    ActiveRecord::Schema.define do
      drop_table :posts
    end
  end
end

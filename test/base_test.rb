require 'test_helper'

module DbSubsetter
  class Test < MiniTest::Test
    def setup
      ActiveRecord::Base.establish_connection(DB_CONFIG)
      ActiveRecord::Schema.define do
        create_table :posts, force: true do |t|
          t.string :title, null: true
        end
      end
    end

    def setup_db
      @db = DbSubsetter::Database.new(nil)
    end

    def teardown
      ActiveRecord::Schema.define do
        drop_table :posts
      end
      ActiveRecord::Base.connection_pool.disconnect!
    end
  end
end

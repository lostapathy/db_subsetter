require 'test_helper'

module DbSubsetter
  class Test < MiniTest::Test
    def setup
      ActiveRecord::Base.establish_connection(DB_CONFIG)
      ActiveRecord::Schema.define do
        create_table :posts, force: true do |t|
          t.string :title, null: true
        end

        create_table :authors, force: true do |t|
          t.string :name, null: false
        end
      end
    end

    def setup_db
      @exporter = DbSubsetter::Exporter.new
      @db = DbSubsetter::Database.new(@exporter)
    end

    def teardown
      ActiveRecord::Schema.define do
        drop_table :posts
      end
      ActiveRecord::Base.connection_pool.disconnect!
    end

    def add_reference(table, other_table)
      if ActiveRecord::Base.connection_config[:adapter] == 'sqlite3'
        ActiveRecord::Base.connection.execute("alter table #{table} add column #{other_table}_id references #{other_table}(id)")
      else
        ActiveRecord::Schema.define do
          add_reference table, other_table, foreign_key: true
        end
      end
    end
  end
end

require 'test_helper'

module DbSubsetter
  class Test < MiniTest::Test
    def setup
      ActiveRecord::Base.establish_connection(DB_CONFIG)
      ActiveRecord::Schema.verbose = false
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
      Post.reset_column_information
      Author.reset_column_information
    end

    def teardown
      ActiveRecord::Schema.define do
        drop_table :posts
      end
      ActiveRecord::Base.connection_pool.disconnect!
    end

    def add_reference(table, other_table)
      other_table_singular = other_table.to_s.sub(/s$/, '')
      if ActiveRecord::Base.connection_config[:adapter] == 'sqlite3'
        ActiveRecord::Base.connection.execute("alter table #{table} add column #{other_table_singular}_id references #{other_table}(id)")
      else
        ActiveRecord::Schema.define do
          add_reference table, other_table_singular, foreign_key: { to_table: other_table }
        end
      end
    end

    def remove_foreign_key(table, other_table)
      ActiveRecord::Schema.define do
        remove_foreign_key table, other_table
      end
    rescue ArgumentError
      puts "foreign key not defined #{table} to #{other_table}"
    end
  end
end

class Post < ActiveRecord::Base; end
class Author < ActiveRecord::Base; end

require 'test_helper'

class FullStackTest < DbSubsetter::Test
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

    Post.all.delete_all
    Author.all.delete_all

    importer = DbSubsetter::Importer.new('test.sqlite3', DbSubsetter::Dialect::Sqlite)
    importer.import

    assert_equal 42, Post.count
    assert_equal 100, Author.count

    # FIXME: should add more assertions about the content
  ensure
    FileUtils.rm('test.sqlite3') if File.exist?('test.sqlite3')
  end
end

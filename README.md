# db_subsetter

Extract a subset of a relational database for use in development or testing.  Provides a simple API to filter rows and preserve referential integrity.  The extracted data is packed into a [SQLite](https://www.sqlite.org/) database to allow easy copying.

Developing against a realistic dataset extracted from production provides a lot of advantages over starting with an empty database.  This tools was inspired by [rdbms-subsetter](https://github.com/18F/rdbms-subsetter) and [yaml_db](https://github.com/yamldb/yaml_db/) and combines some of the best attributes of both.

When working against a legacy database, automatic relationship management does not always work out.  It can also be desirable to extract similar subsets of data over time to simplify testing.  We provide an API to allow you to quickly define how you want to filter each table for your subset.  We also provide tools to help calibrate your filters to extract a subset of a reasonable size.

ActiveRecord is used for database access, however you *do not* need to have ActiveRecord models for all tables you wish to subset.  Any database supported by ActiveRecord should work.  In theory, you should be able to subset from database and import into another (i.e., MySQL -> Postgres), however in practice this may or may not work well depending on exactly what data types are used.


## Installation

Add this line to your application's Gemfile:

```ruby
gem 'db_subsetter'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install db_subsetter

## Usage

TODO: Write usage instructions here

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## TODO

* Improve the dialect handling
* Better example docs on usage and filtering examples
* Implement a scrubber API to allow sanitizing or correcting data at export time.  This allows us to keep sensitive/personal data out of the export and also allows correction of broken data that won't re-insert.
* Add an executable and/or rake task to perform export and import rather than requiring the API to used directly.  Will need a config file to specific custom plugins
* Add pre-flight check on import to make sure all tables smell like they will load the data (right columns, at minimum)
* Finish building and test checks to make sure foreign keys are valid after import

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/lostapathy/db_subsetter.



## License


The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).


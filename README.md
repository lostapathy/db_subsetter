<!-- vim: set nofoldenable: -->
# db_subsetter

[![Build Status](https://travis-ci.org/lostapathy/db_subsetter.svg?branch=master)](https://travis-ci.org/lostapathy/db_subsetter)
[![Maintainability](https://api.codeclimate.com/v1/badges/26b61bf940b79bbfa529/maintainability)](https://codeclimate.com/github/lostapathy/db_subsetter/maintainability)
[![Test Coverage](https://codeclimate.com/github/lostapathy/db_subsetter/badges/coverage.svg)](https://codeclimate.com/github/lostapathy/db_subsetter/coverage)

![db_subsetter logo](/logo/db_subsetter_logo.png?raw=true "db_subsetter logo")

Extract a subset of a relational database for use in development or testing.  Provides a simple API to filter rows and preserve referential integrity.  The extracted data is packed into a [SQLite](https://www.sqlite.org/) database to allow easy copying.

Developing against a realistic dataset extracted from production provides a lot of advantages over starting with an empty database.  This tools was inspired by [rdbms-subsetter](https://github.com/18F/rdbms-subsetter) and [yaml_db](https://github.com/yamldb/yaml_db/) and combines some of the best attributes of both.

When working against a legacy database, automatic relationship management does not always work out.  It can also be desirable to extract similar subsets of data over time to simplify testing.  We provide an API to allow you to quickly define how you want to filter each table for your subset.  We also provide tools to help calibrate your filters to extract a subset of a reasonable size.

ActiveRecord is used for database access, however you *do not* need to have ActiveRecord models for all tables you wish to subset.  Any database supported by ActiveRecord should work.  In theory, you should be able to subset from database and import into another (i.e., MySQL -> Postgres), however in practice this may or may not work well depending on exactly what data types are used.

## RDBMS Support

db_subsetter requires a small RDBMS-specific adapter in order to deal with a few things during the export/import process, mainly related to foreign keys.  At present, the following dialects are supported.  Writing others is pretty straightforward, PRs welcome.

* MySQL
* MS SQL
* Postgres
* Sqlite

## Limitations

Over time we hope to remove some of these limitations.  Until then, tables affected by these limitations can either be skipped or processed manually.

* Tables to be exported must have a single-column primary key unless they have less than SELECT_BATCH_SIZE (5000) rows
* Foreign keys that do not point back to a primary key are not automatically filtered on

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

db_subsetter is a toolset for creating export/import scripts to export and import your data.  There is no command to run, rather, you build your own scripts.  These instructions give an overview of how to build up a typical configuration to export a subset of data for typical development workflows, but should just be considered a starting point.

### Prerequisites

The examples provided here assume you are using db_subsetter in the context of a Rails app and that ActiveRecord is already configured and "just works."  This is just done for brevity in the example scripts, as db_subsetter absolutely does not require you to use Rails.  Using Rails just makes some operations a little more convenient.  If you aren't a Rails user, you'll need to add code (after the require statements) to connect ActiveRecord, such as:

```ruby
ActiveRecord::Base.establish_connection(
  adapter: "mysql2",
  host: "127.0.0.1",
  username: "dbuser",
  database: "huge_db"
)
```
### A Minimal Start

We'll start our example with a minimal export.rb and build up from there.  This

```ruby
#!/usr/bin/env ruby
require 'db_subsetter'

exporter = DbSubsetter::Exporter.new
filename = "project-#{Rails.env}.sqlite3"
FileUtils.rm(filename) if File.exists?(filename)

exporter.export(filename)
```
Time to run it against our db and see what happens!




TODO: These instructions are a work in progress.  More to come!

## Applications

The obvious application of db_subsetter is to provide a subset for development. There are many other non-obvious uses.

* Capture state when an exception occurs to ease in reproducing the problem
* Creating reproducible scenarios for complex integration tests
* Exporting the underlying data used to generate a report, for compliance and audit purposes
* Archival before deletion of data
* Providing customers with their own data
* Migration between RDBMS systems

Come up with something else?  Please file an issue or submit a PR, we'd love to hear about it!

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Roadmap

* 0.4.x (released) - fully functional, requires manual filtering of all tables
* 0.5.x (December 2017) - automating filtering of tables by foreign keys, requires much less configuration but will have small breaking API changes
* 0.6.x (TBA) - improve/expand the scrambler API to allow much simpler filtering of tables, breaking changes to scrambler API likely

## TODO

* Improve the dialect handling (detect dialect automatically in the importer)
* Better example docs on usage and filtering examples
* Implement a scrubber API to allow sanitizing or correcting data at export time.  This allows us to keep sensitive/personal data out of the export and also allows correction of broken data that won't re-insert.
* Add an executable and/or rake task to perform export and import rather than requiring the API to used directly.  Will need a config file to specific custom plugins
* Add pre-flight check on import to make sure all tables smell like they will load the data (right columns, at minimum)
* Examples of validating referential integrity after import
* Add a verbose mode to display more detailed stats while running an export or import (what table we're on, records exported, time taken)
* Decouple generating the subset from outputting it, so we could have alternate outputs - like sending direct to another db
* Provide an alternate API to allow filtering without dealing directly with Arel.  Perhaps a method to pass in an array of IDs to filter from?
* Add API calls to allow columns to be skipped completely when subsetting

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/lostapathy/db_subsetter.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).


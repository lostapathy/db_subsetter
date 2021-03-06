lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'db_subsetter/version'

Gem::Specification.new do |spec|
  spec.name          = 'db_subsetter'
  spec.version       = DbSubsetter::VERSION
  spec.authors       = ['Joe Francis']
  spec.email         = ['joe@lostapathy.com']

  spec.summary       = %q(Extract a subset of a relational database for use in development or
                          testing.  Provides a simple API to filter rows and preserve referential
                          integrity.)
  # spec.description   = %q{TODO: Write a longer description or delete this line.}
  spec.homepage      = 'https://github.com/lostapathy/db_subsetter'
  spec.license       = 'MIT'

  spec.files         = Dir.glob('{lib}/**/*') + %w[LICENSE README.md]
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_development_dependency 'appraisal'
  spec.add_development_dependency 'bundler', '~> 1.12'
  spec.add_development_dependency 'minitest', '~> 5.0'
  spec.add_development_dependency 'mysql2', '~> 0.4.10'
  spec.add_development_dependency 'pg', '~> 0.21.0'
  spec.add_development_dependency 'rake', '>= 12.3.3'

  spec.add_dependency 'activerecord', '>= 4.2.6'
  spec.add_dependency 'random-word', '~> 1.3'
  spec.add_dependency 'sqlite3', '~> 1.3'
end

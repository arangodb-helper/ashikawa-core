# Ashikawa Core

**This gem is not maintained. If you want to take over the project, please contact info@arangodb.com**

| Project         | Ashikawa::Core
|:----------------|:--------------------------------------------------
| Homepage        | http://triagens.github.io/ashikawa-core/
| Documentation   | [RubyDoc](http://www.rubydoc.info/gems/ashikawa-core)
| CI              | [![Build Status](http://img.shields.io/travis/triAGENS/ashikawa-core.svg)](http://travis-ci.org/triAGENS/ashikawa-core)
| Code Metrics    | [![Code Climate](http://img.shields.io/codeclimate/github/triAGENS/ashikawa-core.svg)](https://codeclimate.com/github/triAGENS/ashikawa-core) [![Code Climate Coverage](http://img.shields.io/codeclimate/coverage/github/triAGENS/ashikawa-core.svg)](https://codeclimate.com/github/triAGENS/ashikawa-core)
| Inline docs     | [![Inline docs](http://inch-ci.org/github/triAGENS/ashikawa-core.svg)](http://inch-ci.org/github/triAGENS/ashikawa-core)
| Gem Version     | [![Gem Version](http://img.shields.io/gem/v/ashikawa-core.svg)](http://rubygems.org/gems/ashikawa-core)
| Dependencies    | [![Dependency Status](http://img.shields.io/gemnasium/triAGENS/ashikawa-core.svg)](https://gemnasium.com/triAGENS/ashikawa-core)

Ashikawa Core is a Wrapper around the ArangoDB Rest API. It provides low level access and is intended to be used in ArangoDB ODMs and other projects related to the database. It is always working with the stable version of ArangoDB, this is currently version **2.4**.

All tests run on Travis CI for the following versions of Ruby:

* MRI 1.9.3, 2.1.5 and 2.2.0
* JRuby 1.7.12

## How to install it?

```shell
gem install ashikawa-core
```

or, when using bundler:

```ruby
gem "ashikawa-core"
```

## How to Setup a Connection?

We want to provide you with as much flexibility as possible. So you can choose which adapter to use for HTTP (choose from the adapters available for [Faraday](https://github.com/lostisland/faraday)) and what you want to use for logging (basically anything that has an `info` method that takes a String). It defaults to Net::HTTP and no logging:

```ruby
database = Ashikawa::Core::Database.new do |config|
  config.url = "http://localhost:8529"
end
```

If you want to access the `my_db` database of your ArangoDB instance (and not the `_system` database) and connect as a certain user, do the following:

```ruby
database = Ashikawa::Core::Database.new do |config|
  config.url = "http://localhost:8529"
  configl.database_name = 'my_db'
  config.username = "lebowski"
  config.password = "i<3bowling"
end
```

But you could for example use Typhoeus for HTTP and yell for logging:

```ruby
require "typhoeus"
require "yell"

logger = Yell.new(STDOUT)

database = Ashikawa::Core::Database.new do |config|
  config.url = "http://localhost:8529"
  config.adapter = :typhoeus
  config.logger = logger
end
```

For a detailed description on how to use Ashikawa::Core please refer to the [documentation](http://rdoc.info/gems/ashikawa-core/frames). An example:

```ruby
database["my_collection"] # => Returns the collection my_collection – creates it, if it doesn't exist
database["my_collection"].name = "new_name"
database["new_name"].delete
```

# Issues or Questions

If you find a bug in this gem, please report it on [our tracker](https://github.com/triAGENS/ashikawa-core/issues). If you have a question, just contact us via the [mailing list](https://groups.google.com/forum/?fromgroups#!forum/ashikawa) – we are happy to help you :smile:

# Contributing

If you want to contribute to the project, see CONTRIBUTING.md for details. It contains information on our process and how to set up everything. The following people have contributed to this project:

* Lucas Dohmen ([@moonglum](https://github.com/moonglum)): Developer
* Tobias Eilert ([@EinLama](https://github.com/EinLama)): Contributor
* Markus Schirp ([@mbj](https://github.com/mbj)): Contributor
* Ettore Berardi ([@ettomatic](https://github.com/ettomatic)): Contributor
* Samuel Richardson ([@Rodeoclash](https://github.com/Rodeoclash)): Contributor
* Nikita Vasiliev ([@sharpyfox](https://github.com/sharpyfox)): Contributor
* Dirk Breuer ([@railsbros-dirk](https://github.com/railsbros-dirk)): Contributor
* Mike Williamson ([@sleepycat](https://github.com/sleepycat)): Contributor
* Ujjwal Thaakar ([@ujjwalt](https://github.com/ujjwalt)): Contributor
* René Föhring ([@rrrene](https://github.com/rrrene)): Contributor

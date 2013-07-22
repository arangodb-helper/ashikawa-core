# Ashikawa Core [![Gem Version](https://badge.fury.io/rb/ashikawa-core.png)](http://badge.fury.io/rb/ashikawa-core) [![Build Status](https://secure.travis-ci.org/triAGENS/ashikawa-core.png?branch=master)](http://travis-ci.org/triAGENS/ashikawa-core) [![Dependency Status](https://gemnasium.com/triAGENS/ashikawa-core.png)](https://gemnasium.com/triAGENS/ashikawa-core) [![Code Climate](https://codeclimate.com/github/triAGENS/ashikawa-core.png)](https://codeclimate.com/github/triAGENS/ashikawa-core) [![Coverage Status](https://coveralls.io/repos/triAGENS/ashikawa-core/badge.png?branch=coverall)](https://coveralls.io/r/triAGENS/ashikawa-core)

Ashikawa Core is a Wrapper around the ArangoDB Rest API. It provides low level access and will be used in different ArangoDB ODMs and other projects related to the database. It is always working with the stable version of ArangoDB, this is currently version **1.3**. If you want to access an ArangoDB instance running version **1.2** or use Ruby 1.8 refer to version [0.7](https://github.com/triAGENS/ashikawa-core/tree/0.7) of this gem (or just update ;) ).

All tests run on Travis CI for the following versions of Ruby:

* MRI 1.9.2, 1.9.3 and 2.0.0
* Rubinius 1.9 mode
* JRuby 1.9 mode

We also run on JRuby and MRI Head, but they are allowed failures (Please see [Travis](http://travis-ci.org/triAGENS/ashikawa-core) for their build status).

Please note that the [`master`](https://github.com/triAGENS/ashikawa-core) branch is always the stable version released on Ruby Gems and documented on RDoc. If you want the most recent version, please refer to the [`development`](https://github.com/triAGENS/ashikawa-core/tree/development) branch.

## How to Setup a Connection

We want to provide you with as much flexibility as possible. So you can choose which adapter to use for HTTP (choose from the adapters available for [Faraday](https://github.com/lostisland/faraday)) and what you want to use for logging (basically anything that has an `info` method that takes a String). It defaults to Net::HTTP and no logging:

```ruby
database = Ashikawa::Core::Database.new do |config|
  config.url = "http://localhost:8529"
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

For a detailed description on how to use Ashikawa::Core please refer to the [documentation](http://rdoc.info/github/triAGENS/ashikawa-core/master/frames). An example:

```ruby
database["my_collection"] # => Returns the collection my_collection – creates it, if it doesn't exist
database["my_collection"].name = "new_name"
database["new_name"].delete
```

# Issues or Questions

If you find a bug in this gem, please report it on [our tracker](https://github.com/triAGENS/ashikawa-core/issues). If you have a question, just contact us via the [mailing list](https://groups.google.com/forum/?fromgroups#!forum/ashikawa) – we are happy to help you :)

# Contributing

If you want to contribute to the project, see CONTRIBUTING.md for details. It contains information on our process and how to set up everything. The following people have contributed to this project:

* Lucas Dohmen ([@moonglum](https://github.com/moonglum)): Developer
* Tobias Eilert ([@EinLama](https://github.com/EinLama)): Contributor
* Markus Schirp ([@mbj](https://github.com/mbj)): Contributor
* Ettore Berardi ([@ettomatic](https://github.com/ettomatic)): Contributor
* Samuel Richardson ([@Rodeoclash](https://github.com/Rodeoclash)): Contributor

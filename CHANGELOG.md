# Version 0.14.0

**Codename: Armstrong**

* Making `add_vertex_collection` and `add_edge_definition` idempotent (#144, #139)
* Introduced `add_vertex_collection!` and `add_edge_definition!` which will raise errors
* Making error messages and error numbers from ArangoDB more visible in exceptions (#136)
* Small improvements to the docuemtation
* Running against Ruby 2.2.0 now

# Version 0.13.1

* **Important Bugfix: Please update immediately**
* Fixes associating documents with the graph if loaded through a `VertexCollection` (#137)

# Version 0.13.0

**Codename: Galadriel**

* Support for the [new Graph module](http://docs.arangodb.com/HttpGharial/README.html)  in Arango 2.2 (#55)
* Fixed badge URL for Inch (#130)
* **Deprecated** `Collection#create_edge` in favor of `EdgeCollection#add`
* Sending the `X-Arango-Version` HTTP header with each request (#82)
* Development only:
  * Removed Rubinius from Travis
  * You will need ArangoDB 2.2 for development
  * Automatically removed auto-generated databases for acceptance specs

# Version 0.12.0

**Codename: V for Verifying**

* Support for ArangoDB 2.1
* Accept single attributes in add_index (#120)
* JSON is no longer a runtime dependency but a development dependency (#118)
* Make database name explicit (#117)
* **Breaking Change:** Removed 'prima donna methods' 
* Using a less verbose logging middleware (#124)
* Refactored the internal connection creation to support better external configuration (#126)
* Development only:
  * Using Rspec 3.0
  * Switched to verifying doubles
* New Contributors
  * Ujjwal Thaakar (@ujjwalt)
  * René Föhring (@rrrene)

# Version 0.11

**Codename: R3C0NF1GUR3D**

* Only supports ArangoDB 2.0 officially from now on.
* **Breaking Change:** Collection#truncate! is now Collection#truncate
* New feature: Create and Drop Databases – and get their name and truncate all collections at once #103 
* New feature: Allow to pass `bind_vars` to the execution of AQL #107 #113 
* Dependency Update: Faraday and Faraday Middleware #111 
* Documentation Improvements #95 
* README improvements #100 #102 #106 
* Development Setup Changes:
    * Removed Devtools entirely #93 
    * Updated to RSpec 3.0 #94 #112 
    * Use HoundCI as our code style checker #105 
    * Use Inch for documentation checking #93 
    * Bring all development dependencies up to date #111 
* New Contributors
    * Mike Williamson (@sleepycat)

*Codename in honor of Daft Punk.*

# Version 0.10

**Codename: Sepia Tone Laboratory**

* Support for ArangoDB 1.4 and 2.0
* Big Refactoring Release
    * Including significant refactoring of the test suite
* Breaking change:
    * `Document#hash` is now `Document#to_h`. This was a huge mistake before, sorry for that! #86
* Bug Fixes:
    * Crashes on Rubinius have been fixed – it's now supported #75
* Allow the usage of both keys and IDs for `Collection#fetch` and `Collection#replace` #77
* Logging
    * Don't spam the log files #88
* Use Faraday Middleware and middleware included in Faraday instead of custom tailored middleware #92
* The branching model has been changed: There's no development branch anymore
    * This was confusing to both users and contributors #79
* Other adjustments:
    * Most classes are now 100% mutation tested via mutant #37
* New Contributors
    * Nikita Vasiliev (@sharpyfox)
    * Dirk Breuer (@railsbros-dirk)

*Codename in honor of Lifeformed.*

# Version 0.9

**Codename: Weramur**

* Support for ArangoDB 1.4
* Dropping support for Ruby 1.9.2
* Additions:
    * Support for multiple databases
    * Create unique indexes
* Performance Improvements:
    * Document creation is faster now
* Deprecations: 
    * `Database#authenticate_with`: Use the initializer block instead
    * Methods deprecated in 0.8 were removed
* Bug Fixes:
    * Getting single attributes via an AQL query works now
* Continuous Integration
    * All specs now also run on a ArangoDB with authentication activated
* A lot of refactoring, more enforced coding guidelines
    * Especially the Specs were heavily refactored
    * Specs are now in the new RSpec Syntax

*Codename in honor of Saor Patrol.*

# Version 0.8

[Release on Github](https://github.com/triAGENS/ashikawa-core/releases/tag/v0.8.0)

**Codename: Timer Koala Sing**

* Support for ArangoDB 1.3
* Dropping support for Ruby 1.8.7
* API changes:
  * `Database#collections` no longer returns system collections, use `Database#system_collections` for that
  * Renamed `Collection#[]` to `Collection#fetch` and introducing a new `Collection#[]` method
* Additions:
  * Support for Auto Increment
* Deprecations:
  * `Collection#<<` (use `Collection#create_document` instead)
  * `Collection#[]=` (use `Collection#replace` instead)
  * `Document#to_hash` (use `Collection#hash` instead)
* Improvements:
  * Introduction of Equality methods and better `inspect` methods via Equalizer
  * Improved error handling for Arango errors
  * MultiJSON was removed
  * Support for Transactions
* Various Bug Fixes, Dependency Updates and Refactorings

*Codename in honor of Federico Viticci, President of Special Business.*

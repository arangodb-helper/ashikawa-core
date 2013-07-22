## Specs
# Difference to Devtools:
# * Acceptance, no integration tests
# * Special Case: ArangoDB needed for Acceptance Tests

Rake::Task["spec"].clear
Rake::Task["spec:integration"].clear

desc 'Run all specs'
task :spec => %w[ spec:unit spec:acceptance ]

namespace :spec do
  desc "Run the acceptance tests. Requires ArangoDB to be running."
  RSpec::Core::RakeTask.new(:acceptance) do |spec|
    spec.pattern = "spec/acceptance/*_spec.rb"
  end

  desc "Run the acceptance tests. Requires ArangoDB."
  RSpec::Core::RakeTask.new(:start_arango_and_run_acceptance) do |spec|
    spec.rspec_opts = "--require acceptance/arango_helper.rb"
    spec.pattern = "spec/acceptance/*_spec.rb"
  end

  desc "Run the authentication acceptance tests. Requires ArangoDB."
  RSpec::Core::RakeTask.new(:start_arango_and_run_acceptance_auth) do |spec|
    spec.rspec_opts = "--require acceptance_auth/arango_helper.rb"
    spec.pattern = "spec/acceptance_auth/*_spec.rb"
  end
end

## Metrics
# Differences to Devtools:
# * Do not run mutant yet
# * metrics task only runs metrics (and not specs)

Rake::Task["ci"].clear
Rake::Task["ci:metrics"].clear

namespace :ci do
  desc 'Run all metrics except mutant and reek'
  task :metrics => %w[
    metrics:coverage
    metrics:yardstick:verify
    metrics:rubocop
    metrics:flog
    metrics:flay
    metrics:reek
  ]
end

desc 'Run all metrics and specs'
task :ci => %w[
  spec
  ci:metrics
]

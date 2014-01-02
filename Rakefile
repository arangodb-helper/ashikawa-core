#!/usr/bin/env rake
# -*- encoding : utf-8 -*-
require 'devtools'
require 'bundler/gem_tasks'
require 'rspec/core/rake_task'

Devtools.init_rake_tasks

import('./tasks/adjustments.rake')

# Default task is running everything except mutant
task default: %w[ spec ci:metrics ]

require "bundler/gem_tasks"
require "rspec/core/rake_task"

require 'solr_wrapper'
require 'fcrepo_wrapper'
require 'active_fedora/rake_support'

RSpec::Core::RakeTask.new(:spec)

task default: [:ci]

desc "CI build"
task :ci do
  ENV['environment'] = "test"
  Rake::Task['rubocop'].invoke unless ENV['NO_RUBOCOP']

  with_test_server do
    Rake::Task['spec'].invoke
  end
end

require 'rubocop/rake_task'
desc 'Run style checker'
RuboCop::RakeTask.new(:rubocop) do |task|
  task.requires << 'rubocop-rspec'
  task.fail_on_error = true
end

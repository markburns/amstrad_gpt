# frozen_string_literal: true

require "./lib/spec_helper"
require "rake"
require "rspec/core/rake_task"
require "bundler/gem_tasks"

RSpec::Core::RakeTask.new(:spec) do |t|
  t.pattern = "lib/**/*_spec.rb"
end

task default: :spec

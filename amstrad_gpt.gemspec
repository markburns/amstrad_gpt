# frozen_string_literal: true

require_relative "lib/amstrad_gpt/version"

Gem::Specification.new do |spec|
  spec.name = "amstrad_gpt"
  spec.version = AmstradGpt::VERSION
  spec.authors = ["Mark Burns"]
  spec.email = ["markburns@users.noreply.github.com"]

  spec.summary = "Talk to ChatGPT from an Amstrad CPC via a ruby gateway"
  spec.description = "Connects over RS232, supports response streaming"
  spec.homepage = "https://github.com/markburns/amstrad_gpt"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.0.0"

  spec.metadata["allowed_push_host"] = "https://rubygems.org"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/tree/main/CHANGELOG.md"

  gemspec = File.basename(__FILE__)

  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .github appveyor Gemfile])
    end
  end

  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency 'sinatra'
  spec.add_dependency 'crack'
  spec.add_dependency 'faraday'
  spec.add_dependency 'rubyserial'
  spec.add_dependency 'activesupport'
  spec.add_dependency 'commander'
  spec.add_dependency 'sinatra-contrib'
  spec.add_dependency "rackup", "~> 2.1"
  spec.add_dependency "chunky_png"
end

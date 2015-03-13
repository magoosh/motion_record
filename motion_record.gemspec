# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'motion_record/version'

Gem::Specification.new do |spec|
  spec.name          = "motion_record"
  spec.version       = MotionRecord::VERSION
  spec.authors       = ["Zach Millman"]
  spec.email         = ["zach.millman@gmail.com"]
  spec.description   = %q{Mini ActiveRecord for RubyMotion}
  spec.summary       = %q{Miniature ActiveRecord for RubyMotion to use SQLite for storing your objects}
  spec.homepage      = "https://github.com/magoosh/motion_record"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
end

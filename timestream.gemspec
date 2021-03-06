# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "timestream/version"

Gem::Specification.new do |s|
  s.name        = "timestream"
  s.version     = Timestream::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Luke Imhoff"]
  s.email       = ["luke@cray.com"]
  s.homepage    = ""
  s.summary     = "Timestream"
  s.description = "Converts Hamster report to EAR to JDE Timecard"

  s.rubyforge_project = "timestream"
  
  s.add_dependency("chronic")
  s.add_dependency("ruby-dbus")
  s.add_dependency("spreadsheet")
  s.add_dependency("terminal-table")

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end

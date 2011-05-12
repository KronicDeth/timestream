# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "wax/version"

Gem::Specification.new do |s|
  s.name        = "wax"
  s.version     = Wax::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Luke Imhoff"]
  s.email       = ["luke@cray.com"]
  s.homepage    = ""
  s.summary     = "Work Accounting Xcelerator"
  s.description = "Converts Hamster report to EAR to JDE Timecard"

  s.rubyforge_project = "wax"
  
  s.add_dependency("spreadsheet")

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end

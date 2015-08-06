# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "infopark/ses/version"

Gem::Specification.new do |s|
  s.name        = "infopark_ses"
  s.version     = Infopark::SES::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Infopark AG"]
  s.email       = ["info@infopark.de"]
  s.homepage    = "http://www.infopark.de/"
  s.summary     = %q{Infopark SES Solr integration}
  s.description = %q{Infopark SES integrates Resque and Solr for indexing CMS objects.}

  s.files         = `git ls-files`.split("\n").reject {|p| p =~ /^test_app/}
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_dependency "resque"
  s.add_dependency "rsolr"
  s.add_dependency "resque-multi-job-forks"
end

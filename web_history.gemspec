# -*- encoding: utf-8 -*-
require File.expand_path('../lib/web_history/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Bruno Heidelberger"]
  gem.email         = ["bruno.heidelberger@finambo.com"]
  gem.description   = %q{TODO: Write a gem description}
  gem.summary       = %q{TODO: Write a gem summary}
  gem.homepage      = ""

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "web_history"
  gem.require_paths = ["lib"]
  gem.version       = WebHistory::VERSION

  gem.add_dependency "nokogiri", "~> 1.5"

  gem.add_development_dependency "rspec", "~> 2.10"
  gem.add_development_dependency "factory_girl", "~> 3.5"
  gem.add_development_dependency "webmock", "~> 1.8"
end

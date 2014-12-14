source ENV['GEM_SOURCE'] || "https://rubygems.org"

group :development, :unit_tests do
  gem 'rake',                    :require => false
  gem 'rspec-puppet',            :require => false
  gem 'puppetlabs_spec_helper',  :require => false
  gem 'puppet-lint',             :require => false
  gem 'simplecov',               :require => false
  gem 'puppet_facts',            :require => false
  gem 'json',                    :require => false
end

group :system_tests do
  gem 'beaker-rspec',  :require => false
  gem 'serverspec',    :require => false
end

if facterversion = ENV['FACTER_GEM_VERSION']
  gem 'facter', facterversion, :require => false
else
  gem 'facter', :require => false
end

if puppetversion = ENV['PUPPET_GEM_VERSION']
  gem 'puppet', puppetversion, :require => false
else
  gem 'puppet', :require => false
end

if nokogiriversion = ENV['NOKOGIRI_GEM_VERSION']
  gem 'nokogiri', nokogiriversion, :require => false
else
  gem 'nokogiri', :require => false
end

if mimetypesversion = ENV['MIMETYPES_GEM_VERSION']
  gem 'mime-types', mimetypesversion, :require => false
else
  gem 'mime-types', :require => false
end

# vim:ft=ruby

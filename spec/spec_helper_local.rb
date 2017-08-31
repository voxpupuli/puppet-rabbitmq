require 'rspec-puppet-facts'
include RspecPuppetFacts
                                                    # Original fact sources:
add_custom_fact :puppetversion, Puppet.version      # Facter, but excluded from rspec-puppet-facts
add_custom_fact :staging_http_get, ''               # puppet-staging
add_custom_fact :rabbitmq_version, '3.6.1'          # puppet-rabbitmq

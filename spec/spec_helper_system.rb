require 'rspec-system/spec_helper'
require 'rspec-system-puppet/helpers'
require 'rspec-system-serverspec/helpers'
include Serverspec::Helper::RSpecSystem
include Serverspec::Helper::DetectOS
include RSpecSystemPuppet::Helpers

RSpec.configure do |c|
  # Project root
  proj_root = File.expand_path(File.join(File.dirname(__FILE__), '..'))

  # Enable colour
  c.tty = true

  c.include RSpecSystemPuppet::Helpers

  # This is where we 'setup' the nodes before running our tests
  c.before :suite do
    # Install puppet
    puppet_install

    # We need EPEL for erlang.
    if node.facts['osfamily'] == 'RedHat'
      shell('rpm -i http://mirrors.rit.edu/epel/6/i386/epel-release-6-8.noarch.rpm')
    end

    # Install modules and dependencies
    puppet_module_install(:source => proj_root, :module_name => 'rabbitmq')
    shell('puppet module install garethr-erlang')
    shell('puppet module install puppetlabs-stdlib')
    shell('puppet module install puppetlabs-apt')
  end
end

require 'beaker-rspec'
require 'beaker/puppet_install_helper'

run_puppet_install_helper

UNSUPPORTED_PLATFORMS = [].freeze

RSpec.configure do |c|
  # Project root
  proj_root = File.expand_path(File.join(File.dirname(__FILE__), '..'))

  # Readable test descriptions
  c.formatter = :documentation
  c.before :suite do
    puppet_module_install(source: proj_root, module_name: 'rabbitmq')

    hosts.each do |host|
      if fact('os.family') == 'RedHat' && fact('selinux') == 'true'
        # Make sure selinux is disabled so the tests work.
        on host, puppet('apply', '-e',
                        %("exec { 'setenforce 0': path   => '/bin:/sbin:/usr/bin:/usr/sbin', onlyif => 'which setenforce && getenforce | grep Enforcing', }"))
      end

      on host, puppet('module', 'install', 'puppetlabs-stdlib'), acceptable_exit_codes: [0, 1]
      on host, puppet('module', 'install', 'puppet-archive'), acceptable_exit_codes: [0, 1]

      if fact('os.family') == 'Debian'
        on host, puppet('module', 'install', 'puppetlabs-apt'), acceptable_exit_codes: [0, 1]
      end

      if fact('os.family') == 'RedHat'
        on host, puppet('module', 'install', 'garethr-erlang'), acceptable_exit_codes: [0, 1]
      end
    end
  end
end

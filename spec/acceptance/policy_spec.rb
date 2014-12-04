require 'spec_helper_acceptance'

describe 'rabbitmq policy on a vhost:' do


  context "create policy resource" do
    it 'should run successfully' do
      pp = <<-EOS
      if $::osfamily == 'RedHat' {
        class { 'erlang': epel_enable => true }
        Class['erlang'] -> Class['::rabbitmq']
      }
      class { '::rabbitmq':
        service_manage    => true,
        port              => '5672',
        delete_guest_user => true,
        admin_enable      => true,
      } ->

      rabbitmq_vhost { 'myhost':
        ensure => present,
      } ->

      rabbitmq_policy { 'ha-all@myhost':
        pattern    => '.*',
        priority   => 0,
        applyto    => 'all',
        definition => {
          'ha-mode'      => 'all',
          'ha-sync-mode' => 'automatic',
        },
      }
      EOS

      apply_manifest(pp, :catch_failures => true)
    end

    describe command('rabbitmqctl list_policies -p myhost') do
      its(:stdout) { should match /myhost/ }
      its(:stdout) { should match /ha-all/ }
      its(:stdout) { should match /ha-sync-mode/ }
      its(:stdout) { should match /\.\*/ }
    end

  end
end

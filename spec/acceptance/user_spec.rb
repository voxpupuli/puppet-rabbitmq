require 'spec_helper_acceptance'

describe 'rabbitmq user:' do


  context "create user resource" do
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

      rabbitmq_user { 'dan':
        admin    => true,
        password => 'bar',
      }
      EOS

      apply_manifest(pp, :catch_failures => true)
    end

    describe command('rabbitmqctl list_users | grep dan') do
      its(:stdout) { should match /dan/ }
      its(:stdout) { should match /administrator/ }
    end

  end
end

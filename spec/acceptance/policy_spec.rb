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

      rabbitmq_policy { 'ha-exactly@myhost':
        pattern    => 'ha_.*',
        priority   => 1,
        applyto    => 'all',
        # Workaround for Puppet interpreting numbers as strings
        definition => parsejson('{
          "ha-mode":"exactly",
          "ha-params":2,
          "ha-sync-mode":"automatic"
        }'),
      }
      EOS

      apply_manifest(pp, :catch_failures => true)
      apply_manifest(pp, :catch_changes => true)
    end

    it 'should have the policy' do
      shell('rabbitmqctl -q list_policies -p myhost') do |r|
        vhost, name, pattern, definition, priority = r.stdout.split
        expect(vhost).to eq('myhost')
        expect(name).to eq('ha-exactly')
        expect(pattern).to eq('ha_.*')
        expect(JSON.parse(definition)).to eq({
          'ha-mode' => 'exactly',
          'ha-params' => 2,
          'ha-sync-mode' => 'automatic',
        })
        expect(priority.to_i).to eq(1)
        expect(r.exit_code).to be_zero
      end
    end

  end
end

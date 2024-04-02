# frozen_string_literal: true

require 'spec_helper_acceptance'

describe 'rabbitmq_policy' do
  before(:all) do
    pp = <<-EOS
    class { 'rabbitmq':
      service_manage    => true,
      port              => 5672,
      delete_guest_user => true,
      admin_enable      => true,
    }
    -> rabbitmq_vhost { 'myhost':
      ensure => present,
    }
    EOS

    apply_manifest(pp, catch_failures: true)
  end

  context 'ensure present' do
    it_behaves_like 'an idempotent resource' do
      let(:manifest) do
        <<-PUPPET
        rabbitmq_policy { 'ha-all@myhost':
          pattern    => '.*',
          priority   => 0,
          applyto    => 'all',
          definition => {
            'ha-mode'      => 'all',
            'ha-sync-mode' => 'automatic',
          },
        }
        rabbitmq_policy { 'eu-federation@myhost':
          pattern    => '^eu\\.',
          priority   => 0,
          applyto    => 'all',
          definition => {
            'federation-upstream-set' => 'all',
          },
        }
        PUPPET
      end
    end

    it 'policy exist' do
      shell('rabbitmqctl list_policies -p myhost') do |r|
        expect(r.stdout).to match(%r{myhost.*ha-all.*ha-sync-mode})
        expect(r.stdout).to match(%r{myhost.*eu-federation})
        expect(r.exit_code).to be_zero
      end
    end
  end
end

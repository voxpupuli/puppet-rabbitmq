# frozen_string_literal: true

require 'spec_helper_acceptance'

describe 'rabbitmq_vhost:' do
  before(:all) do
    pp = <<-EOS
    class { 'rabbitmq':
      service_manage    => true,
      port              => 5672,
      delete_guest_user => true,
      admin_enable      => true,
    }
    EOS

    apply_manifest(pp, catch_failures: true)
  end

  context 'ensure present' do
    it_behaves_like 'an idempotent resource' do
      let(:manifest) do
        <<-PUPPET
        rabbitmq_vhost { 'myhost':
          ensure => present,
        }
        PUPPET
      end
    end

    it 'vhost exist' do
      shell('rabbitmqctl list_vhosts') do |r|
        expect(r.stdout).to match(%r{myhost})
        expect(r.exit_code).to be_zero
      end
    end
  end
end

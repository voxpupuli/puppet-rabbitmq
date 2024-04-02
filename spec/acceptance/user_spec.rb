# frozen_string_literal: true

require 'spec_helper_acceptance'

describe 'rabbitmq_user' do
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
        rabbitmq_user { 'dan':
          admin    => true,
          password => 'bar',
        }
        PUPPET
      end
    end

    it 'user exist' do
      shell('rabbitmqctl list_users -q') do |r|
        expect(r.stdout).to match(%r{dan.*administrator})
        expect(r.exit_code).to be_zero
      end
    end
  end

  context 'ensure absent' do
    it_behaves_like 'an idempotent resource' do
      let(:manifest) do
        <<-PUPPET
        rabbitmq_user { 'dan':
          ensure => absent,
        }
        PUPPET
      end
    end

    it 'user removed' do
      shell('rabbitmqctl list_users -q') do |r|
        expect(r.stdout).not_to match(%r{dan\s+})
      end
    end
  end
end

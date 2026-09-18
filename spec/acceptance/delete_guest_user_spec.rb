# frozen_string_literal: true

require 'spec_helper_acceptance'

describe 'rabbitmq with delete_guest_user' do
  rabbitmq_version = ENV.fetch('BEAKER_FACTER_rabbitmq_version', '3.13')

  context 'delete_guest_user' do
    it 'runs successfully' do
      pp = <<-EOS
      class { 'rabbitmq':
        rabbitmq_version  => '#{rabbitmq_version}',
        port              => 5672,
        delete_guest_user => true,
      }
      EOS

      apply_manifest(pp, catch_failures: true)
      shell('rabbitmqctl list_users > /tmp/rabbitmqctl_users')
    end

    describe file('/tmp/rabbitmqctl_users') do
      it { is_expected.to be_file }
      it { is_expected.not_to contain 'guest' }
    end
  end
end

# frozen_string_literal: true

require 'spec_helper_acceptance'

describe 'rabbitmq with delete_guest_user' do
  context 'delete_guest_user' do
    it 'runs successfully' do
      pp = <<-EOS
      class { 'erlang':  } ->
      class { 'rabbitmq':
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

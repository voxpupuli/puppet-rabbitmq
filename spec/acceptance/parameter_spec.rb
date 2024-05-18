# frozen_string_literal: true

require 'spec_helper_acceptance'

describe 'rabbitmq parameter on a vhost:' do
  context 'create parameter resource' do
    it 'runs successfully' do
      pp = <<-EOS
      class { 'erlang':  } ->
      class { 'rabbitmq':
        service_manage    => true,
        port              => 5672,
        delete_guest_user => true,
        admin_enable      => true,
      }

      rabbitmq_plugin { [ 'rabbitmq_federation_management', 'rabbitmq_federation' ]:
        ensure => present
      } ~> Service['rabbitmq-server']

      rabbitmq_vhost { 'fedhost':
        ensure => present,
      } ->

      rabbitmq_parameter { 'documentumFed@fedhost':
        component_name => 'federation-upstream',
        value          => {
          'uri'    => 'amqp://server',
          'expires' => '3600000',
        },
      }
      EOS

      apply_manifest(pp, catch_failures: true)
      apply_manifest(pp, catch_changes: true)
    end

    it 'has the parameter' do
      shell('rabbitmqctl list_parameters -p fedhost') do |r|
        expect(r.stdout).to match(%r{federation-upstream.*documentumFed.*expires.*3600000})
        expect(r.exit_code).to be_zero
      end
    end
  end

  context 'destroy parameter resource' do
    it 'runs successfully' do
      pp = <<-EOS
      rabbitmq_parameter { 'documentumFed@fedhost':
        ensure => absent,
      }
      EOS

      apply_manifest(pp, catch_failures: true)
      apply_manifest(pp, catch_changes: true)
    end

    it 'does not have the parameter' do
      shell('rabbitmqctl list_parameters -q') do |r|
        expect(r.stdout).not_to match(%r{documentumFed\s+})
      end
    end
  end
end

# frozen_string_literal: true

require 'spec_helper_acceptance'

describe 'rabbitmq vhost:' do
  context 'create vhost resource' do
    it 'runs successfully' do
      pp = <<-EOS
      class { 'erlang': repo_source => 'packagecloud' } ->
      class { 'rabbitmq':
        service_manage    => true,
        port              => 5672,
        delete_guest_user => true,
        admin_enable      => true,
      } ->

      rabbitmq_vhost { 'myhost':
        ensure => present,
      }
      EOS

      apply_manifest(pp, catch_failures: true)
      apply_manifest(pp, catch_changes: true)
    end

    it 'has the vhost' do
      shell('rabbitmqctl list_vhosts') do |r|
        expect(r.stdout).to match(%r{myhost})
        expect(r.exit_code).to be_zero
      end
    end
  end
end

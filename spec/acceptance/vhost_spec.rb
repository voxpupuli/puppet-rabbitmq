# frozen_string_literal: true

require 'spec_helper_acceptance'

rabbitmq_version = ENV.fetch('BEAKER_FACTER_rabbitmq_version', '3.13')

describe 'rabbitmq vhost:', if: run_test?(rabbitmq_version, fact('os.name')) do
  let(:use_messaging_sig_pkgs) do
    use_messaging_sig_pkgs?(rabbitmq_version, fact('os.name'))
  end

  context 'create vhost resource' do
    it 'runs successfully' do
      pp = <<-EOS
        class { 'rabbitmq':
          rabbitmq_version      => '#{rabbitmq_version}',
          service_manage        => true,
          port                  => 5672,
          delete_guest_user     => true,
          admin_enable          => true,
          #{class_repo_params(rabbitmq_version, fact('os.name'))}
        }

        -> rabbitmq_vhost { 'myhost':
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

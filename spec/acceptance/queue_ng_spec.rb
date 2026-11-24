# frozen_string_literal: true

require 'spec_helper_acceptance'

rabbitmq_version = ENV.fetch('BEAKER_FACTER_rabbitmq_version', '4.0')

describe 'rabbitmq binding:', if: (run_test?(rabbitmq_version, fact('os.name')) and Gem::Version.new(rabbitmq_version) >= Gem::Version.new('4.0')) do
  context 'create binding and queue resources when using default management port' do
    it 'runs successfully' do
      pp = <<-EOS
        class { 'rabbitmq':
          rabbitmq_version      => '#{rabbitmq_version}',
          service_manage        => true,
          port                  => 5672,
          delete_guest_user     => true,
          admin_enable          => true,
          #{class_repo_params(rabbitmq_version, fact('os.name'))}
        } ->

        rabbitmq_user { 'dan':
          admin    => true,
          password => 'bar',
          tags     => ['monitoring', 'tag1'],
        } ->

        rabbitmq_user_permissions { 'dan@host1':
          configure_permission => '.*',
          read_permission      => '.*',
          write_permission     => '.*',
        }

        rabbitmq_vhost { 'host1':
          ensure => present,
        } ->

        rabbitmq_queue { 'queue1@host1':
          user        => 'dan',
          password    => 'bar',
          durable     => true,
          auto_delete => false,
          ensure      => present,
        }
      EOS

      apply_manifest(pp, catch_failures: true)
      apply_manifest(pp, catch_changes: true)
    end

    it 'has the queue' do
      shell('rabbitmqctl list_queues --quiet --vhost host1') do |r|
        expect(r.stdout).to include('queue1')
        expect(r.exit_code).to be_zero
      end

      shell('rabbitmqadmin --username=dan --password=bar queues list --non-interactive --vhost host1') do |r|
        expect(r.stdout).to include('queue1')
        expect(r.exit_code).to be_zero
      end
    end
  end
end

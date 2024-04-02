# frozen_string_literal: true

require 'spec_helper_acceptance'

describe 'rabbitmq_queue:' do
  before do
    pp = <<-EOS
    class { 'rabbitmq':
      service_manage    => true,
      port              => 5672,
      delete_guest_user => true,
      admin_enable      => true,
    }
    -> rabbitmq_user { 'dan':
      admin    => true,
      password => 'bar',
      tags     => ['monitoring', 'tag1'],
    }
    -> rabbitmq_user_permissions { 'dan@host1':
      configure_permission => '.*',
      read_permission      => '.*',
      write_permission     => '.*',
    }
    rabbitmq_vhost { 'host1':
      ensure => present,
    }
    -> rabbitmq_exchange { 'exchange1@host1':
      user     => 'dan',
      password => 'bar',
      type     => 'topic',
      ensure   => present,
    }
    EOS

    apply_manifest(pp, catch_failures: true)
  end

  context 'when using one routing_key' do
    it_behaves_like 'an idempotent resource' do
      let(:manifest) do
        <<-PUPPET
        rabbitmq_queue { 'queue1@host1':
          user        => 'dan',
          password    => 'bar',
          durable     => true,
          auto_delete => false,
          ensure      => present,
        }
        PUPPET
      end
    end

    it 'queue present' do
      shell('rabbitmqctl list_queues -q -p host1') do |r|
        expect(r.stdout).to match(%r{queue1})
        expect(r.exit_code).to be_zero
      end
    end
  end
end

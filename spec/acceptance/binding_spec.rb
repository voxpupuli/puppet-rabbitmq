# frozen_string_literal: true

require 'spec_helper_acceptance'

describe 'rabbitmq_binding:' do
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
    -> rabbitmq_queue { 'queue1@host1':
      user        => 'dan',
      password    => 'bar',
      durable     => true,
      auto_delete => false,
      ensure      => present,
    }
    EOS

    apply_manifest(pp, catch_failures: true)
  end

  context 'when using one routing_key' do
    it_behaves_like 'an idempotent resource' do
      let(:manifest) do
        <<-PUPPET
        rabbitmq_binding { 'exchange1@queue1@host1':
          user             => 'dan',
          password         => 'bar',
          destination_type => 'queue',
          routing_key      => '#',
          ensure           => present,
        }
        PUPPET
      end
    end

    it 'binding exist' do
      shell('rabbitmqctl list_bindings -q -p host1') do |r|
        expect(r.stdout).to match(%r{exchange1\sexchange\squeue1\squeue\s#})
        expect(r.exit_code).to be_zero
      end
    end

    it 'resource has the queue' do
      shell('rabbitmqctl list_queues -q -p host1') do |r|
        expect(r.stdout).to match(%r{queue1})
        expect(r.exit_code).to be_zero
      end
    end
  end

  context 'when using two routing_keys' do
    it_behaves_like 'an idempotent resource' do
      let(:manifest) do
        <<-PUPPET
        rabbitmq_binding { 'binding 1':
          source           => 'exchange1',
          destination      => 'queue1',
          user             => 'dan',
          vhost            => 'host1',
          password         => 'bar',
          destination_type => 'queue',
          routing_key      => 'test1',
          ensure           => present,
        }
        -> rabbitmq_binding { 'binding 2':
          source           => 'exchange1',
          destination      => 'queue1',
          user             => 'dan',
          vhost            => 'host1',
          password         => 'bar',
          destination_type => 'queue',
          routing_key      => 'test2',
          ensure           => present,
        }
        PUPPET
      end
    end

    it 'resource has the bindings' do
      shell('rabbitmqctl list_bindings -q -p host1') do |r|
        expect(r.stdout).to match(%r{exchange1\sexchange\squeue1\squeue\stest1})
        expect(r.stdout).to match(%r{exchange1\sexchange\squeue1\squeue\stest2})
        expect(r.exit_code).to be_zero
      end
    end

    it 'puppet resource shows a binding' do
      shell('puppet resource rabbitmq_binding') do |r|
        expect(r.stdout).to match(%r{source\s+=>\s+'exchange1',})
      end
    end
  end
end

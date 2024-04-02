# frozen_string_literal: true

require 'spec_helper'

describe Puppet::Type.type(:rabbitmq_binding).provider(:rabbitmqadmin) do
  let(:params) do
    {
      name: 'source@target@/',
      destination_type: :queue,
      routing_key: 'blablub',
      arguments: {}
    }
  end
  let(:type_class) { Puppet::Type.type(:rabbitmq_binding).provider(:rabbitmqadmin) }
  let(:resource) { Puppet::Type.type(:rabbitmq_binding).new(params) }
  let(:provider) { resource.provider }
  let(:instances) { type_class.instances }

  describe '#instances' do
    it 'returns instances' do
      allow(type_class).to receive(:rabbitmqctl_list).with('vhosts').and_return <<~EOT
        /
      EOT
      allow(type_class).to receive(:rabbitmqctl_list).with(
        'bindings', '-p', '/', 'source_name', 'destination_name', 'destination_kind', 'routing_key', 'arguments'
      ).and_return <<~EOT
        exchange\tdst_queue\tqueue\t*\t[]
      EOT
      expect(instances.size).to eq(1)
      expect(instances.map do |prov|
        {
          source: prov.get(:source),
          destination: prov.get(:destination),
          vhost: prov.get(:vhost),
          routing_key: prov.get(:routing_key)
        }
      end).to eq([
                   {
                     source: 'exchange',
                     destination: 'dst_queue',
                     vhost: '/',
                     routing_key: '*'
                   }
                 ])
    end

    it 'returns multiple instances' do
      allow(type_class).to receive(:rabbitmqctl_list).with('vhosts').and_return <<~EOT
        /
      EOT
      allow(type_class).to receive(:rabbitmqctl_list).with(
        'bindings', '-p', '/', 'source_name', 'destination_name', 'destination_kind', 'routing_key', 'arguments'
      ).and_return <<~EOT
        exchange\tdst_queue\tqueue\trouting_one\t[]
        exchange\tdst_queue\tqueue\trouting_two\t[]
      EOT
      expect(instances.size).to eq(2)
      expect(instances.map do |prov|
        {
          source: prov.get(:source),
          destination: prov.get(:destination),
          vhost: prov.get(:vhost),
          routing_key: prov.get(:routing_key)
        }
      end).to eq([
                   {
                     source: 'exchange',
                     destination: 'dst_queue',
                     vhost: '/',
                     routing_key: 'routing_one'
                   },
                   {
                     source: 'exchange',
                     destination: 'dst_queue',
                     vhost: '/',
                     routing_key: 'routing_two'
                   }
                 ])
    end
  end

  describe 'Test for prefetch error' do
    let(:params) do
      {
        name: 'binding1',
        source: 'exchange1',
        destination: 'destqueue',
        destination_type: :queue,
        routing_key: 'blablubd',
        arguments: {}
      }
    end

    it 'exists' do
      allow(type_class).to receive(:rabbitmqctl_list).with('vhosts').and_return <<~EOT
        /
      EOT
      allow(type_class).to receive(:rabbitmqctl_list).with(
        'bindings', '-p', '/', 'source_name', 'destination_name', 'destination_kind', 'routing_key', 'arguments'
      ).and_return <<~EOT
        exchange\tdst_queue\tqueue\t*\t[]
      EOT

      type_class.prefetch({})
    end

    it 'matches' do
      # Test resource to match against
      allow(type_class).to receive(:rabbitmqctl_list).with('vhosts').and_return <<~EOT
        /
      EOT
      allow(type_class).to receive(:rabbitmqctl_list).with(
        'bindings', '-p', '/', 'source_name', 'destination_name', 'destination_kind', 'routing_key', 'arguments'
      ).and_return <<~EOT
        exchange\tdst_queue\tqueue\t*\t[]
      EOT

      type_class.prefetch('binding1' => resource)
    end
  end

  describe '#create' do
    it 'calls rabbitmqadmin to create' do
      allow(type_class).to receive(:rabbitmqadmin).with(
        'declare', 'binding', '--vhost=/', '--user=guest', '--password=guest', '-c', '/etc/rabbitmq/rabbitmqadmin.conf',
        'source=source', 'destination=target', 'arguments={}', 'routing_key=blablub', 'destination_type=queue'
      )
      provider.create
    end

    context 'specifying credentials' do
      let(:params) do
        {
          name: 'source@test2@/',
          destination_type: :queue,
          routing_key: 'blablubd',
          arguments: {},
          user: 'colin',
          password: 'secret'
        }
      end

      it 'calls rabbitmqadmin to create' do
        allow(type_class).to receive(:rabbitmqadmin).with(
          'declare', 'binding', '--vhost=/', '--user=colin', '--password=secret', '-c', '/etc/rabbitmq/rabbitmqadmin.conf',
          'source=source', 'destination=test2', 'arguments={}', 'routing_key=blablubd', 'destination_type=queue'
        )
        provider.create
      end
    end

    context 'new queue_bindings' do
      let(:params) do
        {
          name: 'binding1',
          source: 'exchange1',
          destination: 'destqueue',
          destination_type: :queue,
          routing_key: 'blablubd',
          arguments: {}
        }
      end

      it 'calls rabbitmqadmin to create' do
        allow(type_class).to receive(:rabbitmqadmin).with(
          'declare', 'binding', '--vhost=/', '--user=guest', '--password=guest', '-c', '/etc/rabbitmq/rabbitmqadmin.conf',
          'source=exchange1', 'destination=destqueue', 'arguments={}', 'routing_key=blablubd', 'destination_type=queue'
        )
        provider.create
      end
    end
  end

  describe '#destroy' do
    it 'calls rabbitmqadmin to destroy' do
      allow(type_class).to receive(:rabbitmqadmin).with(
        'delete', 'binding', '--vhost=/', '--user=guest', '--password=guest', '-c', '/etc/rabbitmq/rabbitmqadmin.conf',
        'source=source', 'destination_type=queue', 'destination=target', 'properties_key=blablub'
      )
      provider.destroy
    end
  end
end

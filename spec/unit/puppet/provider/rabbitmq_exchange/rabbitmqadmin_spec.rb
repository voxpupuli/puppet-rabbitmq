# frozen_string_literal: true

require 'spec_helper'

describe Puppet::Type.type(:rabbitmq_exchange).provider(:rabbitmqadmin) do
  let(:params) do
    {
      name: 'test.headers@/',
      type: :headers,
      internal: :false,
      durable: :true,
      auto_delete: :false,
      arguments: {
        'hash-headers' => 'message-distribution-hash'
      }
    }
  end
  let(:type_class) { Puppet::Type.type(:rabbitmq_exchange).provider(:rabbitmqadmin) }
  let(:resource) { Puppet::Type.type(:rabbitmq_exchange).new(params) }
  let(:provider) { resource.provider }
  let(:instances) { type_class.instances }

  it 'returns instances' do
    allow(type_class).to receive(:rabbitmqctl_list).with('vhosts').and_return <<~EOT
      /
    EOT
    allow(type_class).to receive(:rabbitmqctl_list).with('exchanges', '-p', '/', 'name', 'type', 'internal', 'durable', 'auto_delete', 'arguments').and_return <<~EOT
              direct  false   true    false   []
      amq.direct      direct  false   true    false   []
      amq.fanout      fanout  false   true    false   []
      amq.headers     headers false   true    false   []
      amq.match       headers false   true    false   []
      amq.rabbitmq.log        topic   true    true    false   []
      amq.rabbitmq.trace      topic   true    true    false   []
      amq.topic       topic   false   true    false   []
      test.headers    x-consistent-hash       false   true    false   [{"hash-header","message-distribution-hash"}]
    EOT
    expect(instances.size).to eq(9)
  end

  it 'calls rabbitmqadmin to create as guest' do
    allow(type_class).to receive(:rabbitmqadmin).with('declare', 'exchange', '--vhost=/', '--user=guest', '--password=guest', 'name=test.headers', 'type=headers', 'internal=false', 'durable=true', 'auto_delete=false', 'arguments={"hash-headers":"message-distribution-hash"}', '-c', '/etc/rabbitmq/rabbitmqadmin.conf')
    provider.create
  end

  it 'calls rabbitmqadmin to destroy' do
    allow(type_class).to receive(:rabbitmqadmin).with('delete', 'exchange', '--vhost=/', '--user=guest', '--password=guest', 'name=test.headers', '-c', '/etc/rabbitmq/rabbitmqadmin.conf')
    provider.destroy
  end

  context 'specifying credentials' do
    let(:params) do
      {
        name: 'test.headers@/',
        type: :headers,
        internal: 'false',
        durable: 'true',
        auto_delete: 'false',
        user: 'colin',
        password: 'secret',
        arguments: {
          'hash-header' => 'message-distribution-hash'
        }
      }
    end

    it 'calls rabbitmqadmin to create with credentials' do
      allow(type_class).to receive(:rabbitmqadmin).with('declare', 'exchange', '--vhost=/', '--user=colin', '--password=secret', 'name=test.headers', 'type=headers', 'internal=false', 'durable=true', 'auto_delete=false', 'arguments={"hash-header":"message-distribution-hash"}', '-c', '/etc/rabbitmq/rabbitmqadmin.conf')
      provider.create
    end
  end
end

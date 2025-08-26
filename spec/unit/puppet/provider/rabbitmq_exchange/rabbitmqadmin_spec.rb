# frozen_string_literal: true

require 'spec_helper'

provider_class = Puppet::Type.type(:rabbitmq_exchange).provider(:rabbitmqadmin)
describe provider_class do
  let(:resource) do
    Puppet::Type::Rabbitmq_exchange.new(
      name: 'test.headers@/',
      type: :headers,
      internal: :false,
      durable: :true,
      auto_delete: :false,
      arguments: {
        'hash-headers' => 'message-distribution-hash'
      }
    )
  end
  let(:provider) { provider_class.new(resource) }

  it 'returns instances' do
    expect(provider_class).to receive(:rabbitmqctl_list).with('vhosts').and_return(<<~EOT)
      /
    EOT
    expect(provider_class).to receive(:rabbitmqctl_list).with('exchanges', '-p', '/', 'name', 'type', 'internal', 'durable', 'auto_delete', 'arguments').and_return(<<~EOT)
      \tdirect\tfalse\ttrue\tfalse\t[]
      amq.direct\tdirect\tfalse\ttrue\tfalse\t[]
      amq.fanout\tfanout\tfalse\ttrue\tfalse\t[]
      amq.headers\theaders\tfalse\ttrue\tfalse\t[]
      amq.match\theaders\tfalse\ttrue\tfalse\t[]
      amq.rabbitmq.log\ttopic\ttrue\ttrue\tfalse\t[]
      amq.rabbitmq.trace\ttopic\ttrue\ttrue\tfalse\t[]
      amq.topic\ttopic\tfalse\ttrue\tfalse\t[]
      test.headers\tx-consistent-hash\tfalse\ttrue\tfalse\t[{"hash-header","message-distribution-hash"}]
    EOT
    instances = provider_class.instances
    expect(instances.size).to eq(9)
    expect(instances.map do |prov|
             {
               name: prov.get(:name),
               type: prov.get(:type),
               internal: prov.get(:internal),
               durable: prov.get(:durable),
               auto_delete: prov.get(:auto_delete),
               arguments: prov.get(:arguments)
             }
           end).to eq([
                        {
                          name: '@/',
                          type: 'direct',
                          internal: 'false',
                          durable: 'true',
                          auto_delete: 'false',
                          arguments: {}
                        },
                        {
                          name: 'amq.direct@/',
                          type: 'direct',
                          internal: 'false',
                          durable: 'true',
                          auto_delete: 'false',
                          arguments: {}
                        },
                        {
                          name: 'amq.fanout@/',
                          type: 'fanout',
                          internal: 'false',
                          durable: 'true',
                          auto_delete: 'false',
                          arguments: {}
                        },
                        {
                          name: 'amq.headers@/',
                          type: 'headers',
                          internal: 'false',
                          durable: 'true',
                          auto_delete: 'false',
                          arguments: {}
                        },
                        {
                          name: 'amq.match@/',
                          type: 'headers',
                          internal: 'false',
                          durable: 'true',
                          auto_delete: 'false',
                          arguments: {}
                        },
                        {
                          name: 'amq.rabbitmq.log@/',
                          type: 'topic',
                          internal: 'true',
                          durable: 'true',
                          auto_delete: 'false',
                          arguments: {}
                        },
                        {
                          name: 'amq.rabbitmq.trace@/',
                          type: 'topic',
                          internal: 'true',
                          durable: 'true',
                          auto_delete: 'false',
                          arguments: {}
                        },
                        {
                          name: 'amq.topic@/',
                          type: 'topic',
                          internal: 'false',
                          durable: 'true',
                          auto_delete: 'false',
                          arguments: {}
                        },
                        {
                          name: 'test.headers@/',
                          type: 'x-consistent-hash',
                          internal: 'false',
                          durable: 'true',
                          auto_delete: 'false',
                          arguments: { 'hash-header' => 'message-distribution-hash' }
                        }
                      ])
  end

  it 'calls rabbitmqadmin to create as guest' do
    expect(provider).to receive(:rabbitmqadmin).with('declare', 'exchange', '--vhost=/', '--user=guest', '--password=guest', 'name=test.headers', 'type=headers', 'internal=false', 'durable=true', 'auto_delete=false', 'arguments={"hash-headers":"message-distribution-hash"}', '-c', '/etc/rabbitmq/rabbitmqadmin.conf')
    provider.create
  end

  it 'calls rabbitmqadmin to destroy' do
    expect(provider).to receive(:rabbitmqadmin).with('delete', 'exchange', '--vhost=/', '--user=guest', '--password=guest', 'name=test.headers', '-c', '/etc/rabbitmq/rabbitmqadmin.conf')
    provider.destroy
  end

  context 'specifying credentials' do
    let(:resource) do
      Puppet::Type::Rabbitmq_exchange.new(
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
      )
    end
    let(:provider) { provider_class.new(resource) }

    it 'calls rabbitmqadmin to create with credentials' do
      expect(provider).to receive(:rabbitmqadmin).with('declare', 'exchange', '--vhost=/', '--user=colin', '--password=secret', 'name=test.headers', 'type=headers', 'internal=false', 'durable=true', 'auto_delete=false', 'arguments={"hash-header":"message-distribution-hash"}', '-c', '/etc/rabbitmq/rabbitmqadmin.conf')
      provider.create
    end
  end
end

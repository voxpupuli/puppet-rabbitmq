# frozen_string_literal: true

require 'spec_helper'

describe Puppet::Type.type(:rabbitmq_queue).provider(:rabbitmqadmin) do
  let(:params) do
    {
      name: 'test@/',
      durable: :true,
      auto_delete: :false,
      arguments: {}
    }
  end
  let(:type_class) { Puppet::Type.type(:rabbitmq_queue).provider(:rabbitmqadmin) }
  let(:resource) { Puppet::Type.type(:rabbitmq_queue).new(params) }
  let(:provider) { resource.provider }
  let(:instances) { type_class.instances }

  it 'returns instances' do
    allow(type_class).to receive(:rabbitmqctl_list).with('vhosts').and_return <<~EOT
      /
    EOT
    allow(type_class).to receive(:rabbitmqctl_list).with('queues', '-p', '/', 'name', 'durable', 'auto_delete', 'arguments').and_return <<~EOT
      test  true  false []
      test2 true  false [{"x-message-ttl",342423},{"x-expires",53253232},{"x-max-length",2332},{"x-max-length-bytes",32563324242},{"x-dead-letter-exchange","amq.direct"},{"x-dead-letter-routing-key","test.routing"}]
    EOT
    expect(instances.size).to eq(2)
  end

  it 'calls rabbitmqadmin to create' do
    allow(type_class).to receive(:rabbitmqadmin).with('declare', 'queue', '--vhost=/', '--user=guest', '--password=guest', '-c', '/etc/rabbitmq/rabbitmqadmin.conf', 'name=test', 'durable=true', 'auto_delete=false', 'arguments={}')
    provider.create
  end

  it 'calls rabbitmqadmin to destroy' do
    allow(type_class).to receive(:rabbitmqadmin).with('delete', 'queue', '--vhost=/', '--user=guest', '--password=guest', '-c', '/etc/rabbitmq/rabbitmqadmin.conf', 'name=test')
    provider.destroy
  end

  context 'specifying credentials' do
    let(:params) do
      {
        name: 'test@/',
        durable: 'true',
        auto_delete: 'false',
        arguments: {},
        user: 'colin',
        password: 'secret'
      }
    end

    it 'calls rabbitmqadmin to create' do
      allow(type_class).to receive(:rabbitmqadmin).with('declare', 'queue', '--vhost=/', '--user=colin', '--password=secret', '-c', '/etc/rabbitmq/rabbitmqadmin.conf', 'name=test', 'durable=true', 'auto_delete=false', 'arguments={}')
      provider.create
    end
  end
end

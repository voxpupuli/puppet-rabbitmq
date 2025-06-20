# frozen_string_literal: true

require 'spec_helper'

provider_class = Puppet::Type.type(:rabbitmq_queue).provider(:rabbitmqadmin)
describe provider_class do
  let(:resource) do
    Puppet::Type::Rabbitmq_queue.new(
      name: 'test@/',
      durable: :true,
      auto_delete: :false,
      arguments: {}
    )
  end
  let(:provider) { provider_class.new(resource) }

  it 'returns instances' do
    provider_class.expects(:rabbitmqctl_list).with('vhosts').returns <<~EOT
      /
    EOT
    provider_class.expects(:rabbitmqctl_list).with('queues', '-p', '/', 'name', 'durable', 'auto_delete', 'arguments').returns <<~EOT
      test\ttrue\tfalse\t[]
      test2\ttrue\tfalse\t[{"x-message-ttl",342423},{"x-expires",53253232},{"x-max-length",2332},{"x-max-length-bytes",32563324242},{"x-dead-letter-exchange","amq.direct"},{"x-dead-letter-routing-key","test.routing"}]
    EOT
    instances = provider_class.instances
    expect(instances.size).to eq(2)
    expect(instances.map do |prov|
             {
               name: prov.get(:name),
               durable: prov.get(:durable),
               auto_delete: prov.get(:auto_delete),
               arguments: prov.get(:arguments)
             }
           end).to eq([
                        {
                          name: 'test@/',
                          durable: 'true',
                          auto_delete: 'false',
                          arguments: {}
                        },
                        {
                          name: 'test2@/',
                          durable: 'true',
                          auto_delete: 'false',
                          arguments: {
                            'x-message-ttl' => 342_423,
                            'x-expires' => 53_253_232,
                            'x-max-length' => 2332,
                            'x-max-length-bytes' => 32_563_324_242,
                            'x-dead-letter-exchange' => 'amq.direct',
                            'x-dead-letter-routing-key' => 'test.routing'
                          }
                        }
                      ])
  end

  it 'calls rabbitmqadmin to create' do
    provider.expects(:rabbitmqadmin).with('declare', 'queue', '--vhost=/', '--user=guest', '--password=guest', '-c', '/etc/rabbitmq/rabbitmqadmin.conf', 'name=test', 'durable=true', 'auto_delete=false', 'arguments={}')
    provider.create
  end

  it 'calls rabbitmqadmin to destroy' do
    provider.expects(:rabbitmqadmin).with('delete', 'queue', '--vhost=/', '--user=guest', '--password=guest', '-c', '/etc/rabbitmq/rabbitmqadmin.conf', 'name=test')
    provider.destroy
  end

  context 'specifying credentials' do
    let(:resource) do
      Puppet::Type::Rabbitmq_queue.new(
        name: 'test@/',
        durable: 'true',
        auto_delete: 'false',
        arguments: {},
        user: 'colin',
        password: 'secret'
      )
    end
    let(:provider) { provider_class.new(resource) }

    it 'calls rabbitmqadmin to create' do
      provider.expects(:rabbitmqadmin).with('declare', 'queue', '--vhost=/', '--user=colin', '--password=secret', '-c', '/etc/rabbitmq/rabbitmqadmin.conf', 'name=test', 'durable=true', 'auto_delete=false', 'arguments={}')
      provider.create
    end
  end
end

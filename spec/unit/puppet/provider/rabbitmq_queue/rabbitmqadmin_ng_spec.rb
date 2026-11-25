# frozen_string_literal: true

require 'spec_helper'

provider_class = Puppet::Type.type(:rabbitmq_queue).provider(:rabbitmqadmin_ng)
describe provider_class do
  let(:resource) do
    Puppet::Type::Rabbitmq_queue.new(
      name: 'test@/',
      durable: :true,
      auto_delete: :false,
      arguments: {},
    )
  end
  let(:provider) { provider_class.new(resource) }

  it 'returns instances' do
    expect(provider_class).to receive(:rabbitmqctl_list).with('vhosts').and_return(<<~EOT)
      /
    EOT
    expect(provider_class).to receive(:rabbitmqctl_list).with('queues', '-p', '/', 'name', 'durable', 'auto_delete', 'arguments').and_return(<<~EOT)
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
               arguments: prov.get(:arguments),
             }
           end).to eq([
                        {
                          name: 'test@/',
                          durable: 'true',
                          auto_delete: 'false',
                          arguments: {},
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
                            'x-dead-letter-routing-key' => 'test.routing',
                          },
                        },
                      ])
  end

  it 'calls rabbitmqadmin to create' do
    expect(provider).to receive(:rabbitmqadmin_ng).with('--username=guest',
                                                        '--password=guest',
                                                        '--config',
                                                        '/etc/rabbitmq/rabbitmqadmin.conf',
                                                        'queues',
                                                        'declare',
                                                        '--non-interactive',
                                                        '--name=test',
                                                        '--durable=true',
                                                        '--auto-delete=false',
                                                        '--arguments={}',
                                                        '--vhost=/')
    provider.create
  end

  it 'calls rabbitmqadmin to destroy' do
    expect(provider).to receive(:rabbitmqadmin_ng).with('--username=guest',
                                                        '--password=guest',
                                                        '--config',
                                                        '/etc/rabbitmq/rabbitmqadmin.conf',
                                                        'queues',
                                                        'delete',
                                                        '--non-interactive',
                                                        '--name=test',
                                                        '--vhost=/')
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
        password: 'secret',
      )
    end
    let(:provider) { provider_class.new(resource) }

    it 'calls rabbitmqadmin to create' do
      expect(provider).to receive(:rabbitmqadmin_ng).with('--username=colin',
                                                          '--password=secret',
                                                          '--config',
                                                          '/etc/rabbitmq/rabbitmqadmin.conf',
                                                          'queues',
                                                          'declare',
                                                          '--non-interactive',
                                                          '--name=test',
                                                          '--durable=true',
                                                          '--auto-delete=false',
                                                          '--arguments={}',
                                                          '--vhost=/')
      provider.create
    end
  end
end

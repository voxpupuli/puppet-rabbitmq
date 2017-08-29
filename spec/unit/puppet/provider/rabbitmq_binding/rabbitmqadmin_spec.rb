require 'puppet'
require 'mocha/api'
RSpec.configure do |config|
  config.mock_with :mocha
end
provider_class = Puppet::Type.type(:rabbitmq_binding).provider(:rabbitmqadmin)
describe provider_class do
  before do
    @resource = Puppet::Type::Rabbitmq_binding.new(
      name: 'source@target@/',
      destination_type: :queue,
      routing_key: 'blablub',
      arguments: {}
    )
    @provider = provider_class.new(@resource)
  end

  describe '#instances' do
    it 'returns instances' do
      provider_class.expects(:rabbitmqctl).with('list_vhosts', '-q').returns <<-EOT
/
EOT
      provider_class.expects(:rabbitmqctl).with('list_bindings', '-q', '-p', '/', 'source_name', 'destination_name', 'destination_kind', 'routing_key', 'arguments').returns <<-EOT
exchange\tdst_queue\tqueue\t*\t[]
EOT
      instances = provider_class.instances
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
      provider_class.expects(:rabbitmqctl).with('list_vhosts', '-q').returns <<-EOT
/
EOT
      provider_class.expects(:rabbitmqctl).with('list_bindings', '-q', '-p', '/', 'source_name', 'destination_name', 'destination_kind', 'routing_key', 'arguments').returns <<-EOT
exchange\tdst_queue\tqueue\trouting_one\t[]
exchange\tdst_queue\tqueue\trouting_two\t[]
EOT
      instances = provider_class.instances
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
    it 'exists' do
      provider_class.expects(:rabbitmqctl).with('list_vhosts', '-q').returns <<-EOT
/
EOT
      provider_class.expects(:rabbitmqctl).with('list_bindings', '-q', '-p', '/', 'source_name', 'destination_name', 'destination_kind', 'routing_key', 'arguments').returns <<-EOT
exchange\tdst_queue\tqueue\t*\t[]
EOT

      provider_class.prefetch({})
    end

    it 'matches' do
      # Test resource to match against
      @resource = Puppet::Type::Rabbitmq_binding.new(
        name: 'binding1',
        source: 'exchange1',
        destination: 'destqueue',
        destination_type: :queue,
        routing_key: 'blablubd',
        arguments: {}
      )

      provider_class.expects(:rabbitmqctl).with('list_vhosts', '-q').returns <<-EOT
/
EOT
      provider_class.expects(:rabbitmqctl).with('list_bindings', '-q', '-p', '/', 'source_name', 'destination_name', 'destination_kind', 'routing_key', 'arguments').returns <<-EOT
exchange\tdst_queue\tqueue\t*\t[]
EOT

      provider_class.prefetch('binding1' => @resource)
    end
  end

  it 'calls rabbitmqadmin to create' do
    @provider.expects(:rabbitmqadmin).with('declare', 'binding', '--vhost=/', '--user=guest', '--password=guest', '-c', '/etc/rabbitmq/rabbitmqadmin.conf', 'source=source', 'destination=target', 'arguments={}', 'routing_key=blablub', 'destination_type=queue')
    @provider.create
  end

  it 'calls rabbitmqadmin to destroy' do
    @provider.expects(:rabbitmqadmin).with('delete', 'binding', '--vhost=/', '--user=guest', '--password=guest', '-c', '/etc/rabbitmq/rabbitmqadmin.conf', 'source=source', 'destination_type=queue', 'destination=target', 'properties_key=blablub')
    @provider.destroy
  end

  context 'specifying credentials' do
    before do
      @resource = Puppet::Type::Rabbitmq_binding.new(
        name: 'source@test2@/',
        destination_type: :queue,
        routing_key: 'blablubd',
        arguments: {},
        user: 'colin',
        password: 'secret'
      )
      @provider = provider_class.new(@resource)
    end

    it 'calls rabbitmqadmin to create' do
      @provider.expects(:rabbitmqadmin).with('declare', 'binding', '--vhost=/', '--user=colin', '--password=secret', '-c', '/etc/rabbitmq/rabbitmqadmin.conf', 'source=source', 'destination=test2', 'arguments={}', 'routing_key=blablubd', 'destination_type=queue')
      @provider.create
    end
  end

  context 'new queue_bindings' do
    before do
      @resource = Puppet::Type::Rabbitmq_binding.new(
        name: 'binding1',
        source: 'exchange1',
        destination: 'destqueue',
        destination_type: :queue,
        routing_key: 'blablubd',
        arguments: {}
      )
      @provider = provider_class.new(@resource)
    end

    it 'calls rabbitmqadmin to create' do
      @provider.expects(:rabbitmqadmin).with('declare', 'binding', '--vhost=/', '--user=guest', '--password=guest', '-c', '/etc/rabbitmq/rabbitmqadmin.conf', 'source=exchange1', 'destination=destqueue', 'arguments={}', 'routing_key=blablubd', 'destination_type=queue')
      @provider.create
    end
  end
end

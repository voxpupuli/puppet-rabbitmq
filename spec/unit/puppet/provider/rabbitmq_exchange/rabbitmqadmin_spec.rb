require 'puppet'
require 'mocha'
RSpec.configure do |config|
  config.mock_with :mocha
end
provider_class = Puppet::Type.type(:rabbitmq_exchange).provider(:rabbitmqadmin)
describe provider_class do
  before :each do
    @resource = Puppet::Type::Rabbitmq_exchange.new(
      {:name => 'test.headers@/',
       :type => :headers,
       :arguments => {
        "hash-header" => "message-distribution-hash" 
        },
      }
    )
    @provider = provider_class.new(@resource)
  end

  it 'should return instances' do
    provider_class.expects(:rabbitmqctl).with('-q', 'list_vhosts').returns <<-EOT
/
EOT
    provider_class.expects(:rabbitmqctl).with('-q', 'list_exchanges', '-p', '/', 'name', 'type', 'arguments').returns <<-EOT
        direct  []
amq.fanout      fanout  []
amq.match       headers []
amq.rabbitmq.log        topic   []
amq.rabbitmq.trace      topic   []
amq.topic       topic   []
test.headers    headers [{"hash-header","message-distribution-hash"}]
EOT
    instances = provider_class.instances
    instances.size.should == 7
  end

  it 'should call rabbitmqadmin to create as guest' do
    @provider.expects(:rabbitmqadmin).with('declare', 'exchange', '--vhost=/', '--user=guest', '--password=guest', 'name=test.headers', 'type=headers', 'arguments={"hash-header":"message-distribution-hash"}', '-c', '/etc/rabbitmq/rabbitmqadmin.conf')
    @provider.create
  end

  it 'should call rabbitmqadmin to destroy' do
    @provider.expects(:rabbitmqadmin).with('delete', 'exchange', '--vhost=/', '--user=guest', '--password=guest', 'name=test.headers', '-c', '/etc/rabbitmq/rabbitmqadmin.conf')
    @provider.destroy
  end

  context 'specifying credentials' do
    before :each do
      @resource = Puppet::Type::Rabbitmq_exchange.new(
        {:name => 'test.headers@/',
        :type => :headers,
        :user => 'colin',
        :password => 'secret',
        :arguments => {
          "hash-header" => "message-distribution-hash"
        },
      }
      )
      @provider = provider_class.new(@resource)
    end

    it 'should call rabbitmqadmin to create with credentials' do
      @provider.expects(:rabbitmqadmin).with('declare', 'exchange', '--vhost=/', '--user=colin', '--password=secret', 'name=test.headers', 'type=headers', 'arguments={"hash-header":"message-distribution-hash"}', '-c', '/etc/rabbitmq/rabbitmqadmin.conf')
      @provider.create
    end
  end
end

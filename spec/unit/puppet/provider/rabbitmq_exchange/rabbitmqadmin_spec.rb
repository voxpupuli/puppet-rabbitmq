require 'puppet'
require 'mocha'
RSpec.configure do |config|
  config.mock_with :mocha
end
provider_class = Puppet::Type.type(:rabbitmq_exchange).provider(:rabbitmqadmin)
describe provider_class do
  before :each do
    @resource = Puppet::Type::Rabbitmq_exchange.new(
      {:name => 'amq.direct@/',
       :type => :topic}
    )
    @provider = provider_class.new(@resource)
  end

  it 'should return instances' do
    provider_class.expects(:rabbitmqadmin).with('list', 'exchanges').returns <<-EOT
+--------------+-----------------------+---------+-------------+---------+----------+
|    vhost     |         name          |  type   | auto_delete | durable | internal |
+--------------+-----------------------+---------+-------------+---------+----------+
| /            |                       | direct  | False       | True    | False    |
| /            | amq.direct            | direct  | False       | True    | False    |
| /            | amq.fanout            | fanout  | False       | True    | False    |
| /            | amq.headers           | headers | False       | True    | False    |
| /            | amq.match             | headers | False       | True    | False    |
| /            | amq.rabbitmq.log      | topic   | False       | True    | False    |
| /            | amq.rabbitmq.trace    | topic   | False       | True    | False    |
| /            | amq.topic             | topic   | False       | True    | False    |
+--------------+-----------------------+---------+-------------+---------+----------+
EOT
    instances = provider_class.instances
    instances.size.should == 8
  end

  it 'should call rabbitmqadmin to create' do
    @provider.expects(:rabbitmqadmin).with('declare', 'exchange', '--vhost=/', '--user=guest', '--password=guest', 'name=amq.direct', 'type=topic')
    @provider.create
  end

  it 'should call rabbitmqadmin to destroy' do
    @provider.expects(:rabbitmqadmin).with('delete', 'exchange', '--vhost=/', '--user=guest', '--password=guest', 'name=amq.direct')
    @provider.destroy
  end

  context 'specifying credentials' do
    before :each do
      @resource = Puppet::Type::Rabbitmq_exchange.new(
        {:name => 'amq.direct@/',
        :type => :topic,
        :user => 'colin',
        :password => 'secret',
        }
      )
      @provider = provider_class.new(@resource)
    end

    it 'should call rabbitmqadmin to create' do
      @provider.expects(:rabbitmqadmin).with('declare', 'exchange', '--vhost=/', '--user=colin', '--password=secret', 'name=amq.direct', 'type=topic')
      @provider.create
    end
  end
end

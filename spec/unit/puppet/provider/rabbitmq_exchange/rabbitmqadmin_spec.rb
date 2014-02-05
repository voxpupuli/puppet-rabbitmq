require 'puppet'
require 'mocha'
RSpec.configure do |config|
  config.mock_with :mocha
end
provider_class = Puppet::Type.type(:rabbitmq_exchange).provider(:rabbitmqadmin)
describe provider_class do
  before :each do
    @catalog  = mock()
    @resource = Puppet::Type::Rabbitmq_exchange.new({
      :name     => 'amq.direct@/',
      :type     => :topic,
      :catalog  => @catalog,
    })

    @provider = provider_class.new(@resource)
    @catalog.stubs(:resource).then.returns({
      :rabbitmqadmin_user  => 'admin',
      :rabbitmqadmin_pass  => 'admin',
    })
  end

  it 'should return instances' do
    provider_class.expects(:rabbitmqadmin).with('list', 'exchanges', '-uadmin', '-padmin').returns <<-EOT
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
    first     = mock()
    resource  = {
      :first => first 
    }

    first.stubs(:catalog).then.returns(@catalog)

    instances = provider_class.instances(resource)

    instances.size.should == 8
  end

  it 'should ignore no items' do
    provider_class.expects(:rabbitmqadmin).with('list', 'exchanges', '', '').returns <<-EOT
No items
EOT

    instances = provider_class.instances({})

    instances.size.should == 0
  end

  it 'should call rabbitmqadmin to create' do
    @provider.expects(:rabbitmqadmin).with('declare', 'exchange', '--vhost=/', '-uadmin', '-padmin', 'name=amq.direct', 'type=topic')
    @provider.create
  end

  it 'should call rabbitmqadmin to destroy' do
    @provider.expects(:rabbitmqadmin).with('delete', 'exchange', '--vhost=/', '-uadmin', '-padmin', 'name=amq.direct')
    @provider.destroy
  end

  context 'specifying credentials' do
    before :each do
      @resource = Puppet::Type::Rabbitmq_exchange.new({
        :name     => 'amq.direct@/',
        :type     => :topic,
        :user     => 'colin',
        :password => 'secret',
        :catalog  => mock()
      })

      @resource.catalog.stubs(:resource).then.returns({})

      @provider = provider_class.new(@resource)
    end

    it 'should call rabbitmqadmin to create' do
      @provider.expects(:rabbitmqadmin).with('declare', 'exchange', '--vhost=/', '--user=colin', '--password=secret', 'name=amq.direct', 'type=topic')
      @provider.create
    end
  end
end

require 'spec_helper'

provider_class = Puppet::Type.type(:rabbitmq_plugin).provider(:rabbitmqplugins)
describe provider_class do
  let(:resource) do
    Puppet::Type::Rabbitmq_plugin.new(
      name: 'foo'
    )
  end
  let(:provider) { provider_class.new(resource) }

  it 'matches plugins' do
    provider.expects(:rabbitmqplugins).with('list', '-E', '-m').returns("foo\n")
    expect(provider.exists?).to eq(true)
  end

  it 'calls rabbitmqplugins to enable when node not running' do
    provider.class.expects(:rabbitmq_running).returns false
    provider.expects(:rabbitmqplugins).with('enable', 'foo')
    provider.create
  end

  context 'with RabbitMQ version >=3.4.0' do
    it 'calls rabbitmqplugins to enable' do
      provider.class.expects(:rabbitmq_version).returns '3.4.0'
      provider.class.expects(:rabbitmq_running).returns true
      provider.expects(:rabbitmqplugins).with('enable', 'foo')
      provider.create
    end
    it 'calls rabbitmqplugins to enable with offline' do
      provider.resource[:mode] = :offline
      provider.class.expects(:rabbitmq_version).returns '3.4.0'
      provider.class.expects(:rabbitmq_running).returns true
      provider.expects(:rabbitmqplugins).with('enable', 'foo', '--offline')
      provider.create
    end
    it 'calls rabbitmqplugins to enable with online' do
      provider.resource[:mode] = :online
      provider.class.expects(:rabbitmq_version).returns '3.4.0'
      provider.class.expects(:rabbitmq_running).returns true
      provider.expects(:rabbitmqplugins).with('enable', 'foo', '--online')
      provider.create
    end
    it 'calls rabbitmqplugins to enable with best' do
      provider.resource[:mode] = :best
      provider.class.expects(:rabbitmq_version).returns '3.4.0'
      provider.class.expects(:rabbitmq_running).returns true
      provider.expects(:rabbitmqplugins).with('enable', 'foo')
      provider.create
    end
  end

  context 'with RabbitMQ version < 3.4.0' do
    it 'calls rabbitmqplugins to enable' do
      provider.class.expects(:rabbitmq_version).returns '3.3.9'
      provider.class.expects(:rabbitmq_running).returns true
      provider.expects(:rabbitmqplugins).with('enable', 'foo')
      provider.create
    end
    it 'calls rabbitmqplugins to enable with offline' do
      provider.resource[:mode] = :offline
      provider.class.expects(:rabbitmq_version).returns '3.3.9'
      provider.class.expects(:rabbitmq_running).returns true
      provider.expects(:rabbitmqplugins).with('enable', 'foo')
      provider.create
    end
    it 'calls rabbitmqplugins to enable with online' do
      provider.resource[:mode] = :online
      provider.class.expects(:rabbitmq_version).returns '3.3.9'
      provider.class.expects(:rabbitmq_running).returns true
      provider.expects(:rabbitmqplugins).with('enable', 'foo')
      provider.create
    end
    it 'calls rabbitmqplugins to enable with best' do
      provider.resource[:mode] = :best
      provider.class.expects(:rabbitmq_version).returns '3.3.9'
      provider.class.expects(:rabbitmq_running).returns true
      provider.expects(:rabbitmqplugins).with('enable', 'foo')
      provider.create
    end
  end

  it 'calls rabbitmqplugins to disable' do
    provider.expects(:rabbitmqplugins).with('disable', 'foo')
    provider.destroy
  end
end

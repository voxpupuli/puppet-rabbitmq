require 'spec_helper'

require 'puppet/provider/rabbitmq_cli'

provider_class = Puppet::Provider::RabbitmqCli
describe provider_class do
  before do
    # Clear the cached version before each test
    provider_class.remove_instance_variable(:@rabbitmq_version) \
      if provider_class.instance_variable_defined?(:@rabbitmq_version)
  end

  it 'gets the RabbitMQ version' do
    provider_class.expects(:rabbitmqctl).with('-q', 'status').returns '{rabbit,"RabbitMQ","3.1.5"}'
    expect(provider_class.rabbitmq_version).to eq('3.1.5')
  end

  it 'caches the RabbitMQ version' do
    provider_class.expects(:rabbitmqctl).with('-q', 'status').returns '{rabbit,"RabbitMQ","3.7.10"}'
    v1 = provider_class.rabbitmq_version

    # No second expects for rabbitmqctl as it shouldn't be called again
    expect(provider_class.rabbitmq_version).to eq(v1)
  end

  it 'uses correct list options with RabbitMQ < 3.7.9' do
    provider_class.expects(:rabbitmq_version).returns '3.7.8'
    provider_class.expects(:rabbitmqctl).with('list_vhost', '-q').returns ''
    expect(provider_class.rabbitmqctl_list('vhost')).to eq('')
  end

  it 'uses correct list options with RabbitMQ >= 3.7.9' do
    provider_class.expects(:rabbitmq_version).returns '3.7.10'
    provider_class.expects(:rabbitmqctl).with('list_vhost', '-q', '--no-table-headers').returns ''
    expect(provider_class.rabbitmqctl_list('vhost')).to eq('')
  end
end

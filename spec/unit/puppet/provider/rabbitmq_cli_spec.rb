# frozen_string_literal: true

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
    expect(provider_class).to receive(:rabbitmqctl).with('-q', 'status').and_return('     [{rabbit,"RabbitMQ","3.7.28"},')
    expect(provider_class.rabbitmq_version).to eq('3.7.28')
  end

  it 'caches the RabbitMQ version' do
    expect(provider_class).to receive(:rabbitmqctl).with('-q', 'status').and_return('     [{rabbit,"RabbitMQ","3.7.28"},')
    v1 = provider_class.rabbitmq_version

    # No second expects for rabbitmqctl as it shouldn't be called again
    expect(provider_class.rabbitmq_version).to eq(v1)
  end

  it 'gets the RabbitMQ version with version >= 3.8' do
    expect(provider_class).to receive(:rabbitmqctl).with('-q', 'status').and_return('RabbitMQ version: 3.10.6')
    expect(provider_class.rabbitmq_version).to eq('3.10.6')
  end

  it 'uses correct list options with RabbitMQ < 3.7.9' do
    expect(provider_class).to receive(:rabbitmq_version).and_return('3.7.8')
    expect(provider_class).to receive(:rabbitmqctl).with('list_vhost', '-q').and_return('')
    expect(provider_class.rabbitmqctl_list('vhost')).to eq('')
  end

  it 'uses correct list options with RabbitMQ >= 3.7.9' do
    expect(provider_class).to receive(:rabbitmq_version).and_return('3.7.10')
    expect(provider_class).to receive(:rabbitmqctl).with('list_vhost', '-q', '--no-table-headers').and_return('')
    expect(provider_class.rabbitmqctl_list('vhost')).to eq('')
  end
end

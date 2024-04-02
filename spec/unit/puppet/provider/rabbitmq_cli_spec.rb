# frozen_string_literal: true

require 'spec_helper'

require 'puppet/provider/rabbitmq_cli'

describe Puppet::Provider::RabbitmqCli do
  before do
    # Clear the cached version before each test
    described_class.remove_instance_variable(:@rabbitmq_version) \
      if described_class.instance_variable_defined?(:@rabbitmq_version)
  end

  it 'gets the RabbitMQ version' do
    allow(described_class).to receive(:rabbitmqctl).with('-q', 'status').and_return '     [{rabbit,"RabbitMQ","3.7.28"},'
    expect(described_class.rabbitmq_version).to eq('3.7.28')
  end

  it 'caches the RabbitMQ version' do
    allow(described_class).to receive(:rabbitmqctl).with('-q', 'status').and_return '     [{rabbit,"RabbitMQ","3.7.28"},'
    v1 = described_class.rabbitmq_version

    # No second expects for rabbitmqctl as it shouldn't be called again
    expect(described_class.rabbitmq_version).to eq(v1)
  end

  it 'gets the RabbitMQ version with version >= 3.8' do
    allow(described_class).to receive(:rabbitmqctl).with('-q', 'status').and_return 'RabbitMQ version: 3.10.6'
    expect(described_class.rabbitmq_version).to eq('3.10.6')
  end

  it 'uses correct list options with RabbitMQ < 3.7.9' do
    allow(described_class).to receive(:rabbitmq_version).and_return '3.7.8'
    allow(described_class).to receive(:rabbitmqctl).with('list_vhost', '-q').and_return ''
    expect(described_class.rabbitmqctl_list('vhost')).to eq('')
  end

  it 'uses correct list options with RabbitMQ >= 3.7.9' do
    allow(described_class).to receive(:rabbitmq_version).and_return '3.7.10'
    allow(described_class).to receive(:rabbitmqctl).with('list_vhost', '-q', '--no-table-headers').and_return ''
    expect(described_class.rabbitmqctl_list('vhost')).to eq('')
  end
end

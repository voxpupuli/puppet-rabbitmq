# frozen_string_literal: true

require 'spec_helper'

describe Puppet::Type.type(:rabbitmq_plugin).provider(:rabbitmqplugins) do
  let(:params) do
    {
      name: 'foo',
    }
  end
  let(:type_class) { Puppet::Type.type(:rabbitmq_plugin).provider(:rabbitmqplugins) }
  let(:resource) { Puppet::Type.type(:rabbitmq_plugin).new(params) }
  let(:provider) { resource.provider }
  let(:instances) { type_class.instances }

  it 'calls rabbitmqplugins to enable when node not running' do
    allow(type_class).to receive(:rabbitmq_running).and_return false
    allow(type_class).to receive(:rabbitmqplugins).with('enable', 'foo')
    provider.create
  end

  describe '#instances' do
    it 'exists' do
      expect(type_class).to respond_to :instances
    end

    it 'retrieves instances' do
      allow(type_class).to receive(:plugin_list).and_return(%w[foo bar])
      expect(instances.map do |prov|
        {
          name: prov.get(:name)
        }
      end).to eq(
        [
          { name: 'foo' },
          { name: 'bar' }
        ]
      )
    end

    it 'raises error on invalid line' do
      allow(type_class).to receive(:plugin_list).and_return(['  '])
      expect { instances }.to raise_error Puppet::Error, %r{Cannot parse invalid plugins line}
    end
  end

  describe '#plugin_list' do
    it 'exists' do
      expect(type_class).to respond_to :instances
    end

    it 'returns a list of plugins' do
      allow(type_class).to receive(:rabbitmqplugins).with('list', '-e', '-m').and_return("foo\nbar\nbaz\n")
      expect(type_class.plugin_list).to eq(%w[foo bar baz])
    end

    it 'handles no training newline properly' do
      allow(type_class).to receive(:rabbitmqplugins).with('list', '-e', '-m').and_return("foo\nbar")
      expect(type_class.plugin_list).to eq(%w[foo bar])
    end

    it 'handles lines that are not plugins' do
      allow(type_class).to receive(:rabbitmqplugins).with('list', '-e', '-m').and_return("Listing plugins with pattern \".*\" ...\nfoo\nbar")
      expect(type_class.plugin_list).to eq(%w[foo bar])
    end
  end

  describe '#exists?' do
    it 'matches existing plugins' do
      allow(type_class).to receive(:plugin_list).and_return(%w[foo])
      expect(provider.exists?).to be(true)
    end

    it 'returns false for missing plugins' do
      allow(type_class).to receive(:plugin_list).and_return(%w[bar])
      expect(provider.exists?).to be(false)
    end
  end

  context 'with RabbitMQ version >=3.4.0' do
    it 'calls rabbitmqplugins to enable' do
      allow(type_class).to receive(:rabbitmq_version).and_return '3.4.0'
      allow(type_class).to receive(:rabbitmq_running).and_return true
      allow(type_class).to receive(:rabbitmqplugins).with('enable', 'foo')
      provider.create
    end

    it 'calls rabbitmqplugins to enable with offline' do
      provider.resource[:mode] = :offline
      allow(type_class).to receive(:rabbitmq_version).and_return '3.4.0'
      allow(type_class).to receive(:rabbitmq_running).and_return true
      allow(type_class).to receive(:rabbitmqplugins).with('enable', 'foo', '--offline')
      provider.create
    end

    it 'calls rabbitmqplugins to enable with online' do
      provider.resource[:mode] = :online
      allow(type_class).to receive(:rabbitmq_version).and_return '3.4.0'
      allow(type_class).to receive(:rabbitmq_running).and_return true
      allow(type_class).to receive(:rabbitmqplugins).with('enable', 'foo', '--online')
      provider.create
    end

    it 'calls rabbitmqplugins to enable with best' do
      provider.resource[:mode] = :best
      allow(type_class).to receive(:rabbitmq_version).and_return '3.4.0'
      allow(type_class).to receive(:rabbitmq_running).and_return true
      allow(type_class).to receive(:rabbitmqplugins).with('enable', 'foo')
      provider.create
    end
  end

  context 'with RabbitMQ version < 3.4.0' do
    it 'calls rabbitmqplugins to enable' do
      allow(type_class).to receive(:rabbitmq_version).and_return '3.3.9'
      allow(type_class).to receive(:rabbitmq_running).and_return true
      allow(type_class).to receive(:rabbitmqplugins).with('enable', 'foo')
      provider.create
    end

    it 'calls rabbitmqplugins to enable with offline' do
      provider.resource[:mode] = :offline
      allow(type_class).to receive(:rabbitmq_version).and_return '3.3.9'
      allow(type_class).to receive(:rabbitmq_running).and_return true
      allow(type_class).to receive(:rabbitmqplugins).with('enable', 'foo')
      provider.create
    end

    it 'calls rabbitmqplugins to enable with online' do
      provider.resource[:mode] = :online
      allow(type_class).to receive(:rabbitmq_version).and_return '3.3.9'
      allow(type_class).to receive(:rabbitmq_running).and_return true
      allow(type_class).to receive(:rabbitmqplugins).with('enable', 'foo')
      provider.create
    end

    it 'calls rabbitmqplugins to enable with best' do
      provider.resource[:mode] = :best
      allow(type_class).to receive(:rabbitmq_version).and_return '3.3.9'
      allow(type_class).to receive(:rabbitmq_running).and_return true
      allow(type_class).to receive(:rabbitmqplugins).with('enable', 'foo')
      provider.create
    end
  end

  it 'calls rabbitmqplugins to disable' do
    allow(type_class).to receive(:rabbitmqplugins).with('disable', 'foo')
    provider.destroy
  end
end

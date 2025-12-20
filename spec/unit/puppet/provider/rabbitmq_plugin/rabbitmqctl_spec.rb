# frozen_string_literal: true

require 'spec_helper'

provider_class = Puppet::Type.type(:rabbitmq_plugin).provider(:rabbitmqplugins)
describe provider_class do
  let(:resource) do
    Puppet::Type::Rabbitmq_plugin.new(
      name: 'foo'
    )
  end
  let(:provider) { provider_class.new(resource) }

  it 'calls rabbitmqplugins to enable when node not running' do
    expect(provider.class).to receive(:rabbitmq_running).and_return(false)
    expect(provider).to receive(:rabbitmqplugins).with('enable', 'foo')
    provider.create
  end

  describe '#instances' do
    it 'exists' do
      expect(provider_class).to respond_to :instances
    end

    it 'retrieves instances' do
      expect(provider.class).to receive(:plugin_list).and_return(%w[foo bar])
      instances = provider_class.instances
      instances_cmp = instances.map { |prov| { name: prov.get(:name) } }
      expect(instances_cmp).to eq(
        [
          { name: 'foo' },
          { name: 'bar' }
        ]
      )
    end

    it 'raises error on invalid line' do
      expect(provider_class).to receive(:plugin_list).and_return(['  '])
      expect { provider_class.instances }.to raise_error Puppet::Error, %r{Cannot parse invalid plugins line}
    end
  end

  describe '#plugin_list' do
    it 'exists' do
      expect(provider_class).to respond_to :instances
    end

    it 'returns a list of plugins' do
      expect(provider.class).to receive(:rabbitmqplugins).with('list', '-e', '-m').and_return("foo\nbar\nbaz\n")
      expect(provider.class.plugin_list).to eq(%w[foo bar baz])
    end

    it 'handles no training newline properly' do
      expect(provider.class).to receive(:rabbitmqplugins).with('list', '-e', '-m').and_return("foo\nbar")
      expect(provider.class.plugin_list).to eq(%w[foo bar])
    end

    it 'handles lines that are not plugins' do
      expect(provider.class).to receive(:rabbitmqplugins).with('list', '-e', '-m').and_return("Listing plugins with pattern \".*\" ...\nfoo\nbar")
      expect(provider.class.plugin_list).to eq(%w[foo bar])
    end
  end

  describe '#exists?' do
    context 'when plugin exists' do
      it 'returns true' do
        allow(provider_class).to receive(:plugin_list).and_return(['foo'])

        provider_class.prefetch('foo' => resource)

        expect(resource.provider.exists?).to eq(true)
      end
    end

    context 'when plugin does not exist' do
      it 'returns false' do
        allow(provider_class).to receive(:plugin_list).and_return([])

        provider_class.prefetch('foo' => resource)

        expect(resource.provider.exists?).to eq(false)
      end
    end
  end

  context 'with RabbitMQ version >=3.4.0' do
    it 'calls rabbitmqplugins to enable' do
      expect(provider.class).to receive(:rabbitmq_version).and_return('3.4.0')
      expect(provider.class).to receive(:rabbitmq_running).and_return(true)
      expect(provider).to receive(:rabbitmqplugins).with('enable', 'foo')
      provider.create
    end

    it 'calls rabbitmqplugins to enable with offline' do
      provider.resource[:mode] = :offline
      expect(provider.class).to receive(:rabbitmq_version).and_return('3.4.0')
      expect(provider.class).to receive(:rabbitmq_running).and_return(true)
      expect(provider).to receive(:rabbitmqplugins).with('enable', 'foo', '--offline')
      provider.create
    end

    it 'calls rabbitmqplugins to enable with online' do
      provider.resource[:mode] = :online
      expect(provider.class).to receive(:rabbitmq_version).and_return('3.4.0')
      expect(provider.class).to receive(:rabbitmq_running).and_return(true)
      expect(provider).to receive(:rabbitmqplugins).with('enable', 'foo', '--online')
      provider.create
    end

    it 'calls rabbitmqplugins to enable with best' do
      provider.resource[:mode] = :best
      expect(provider.class).to receive(:rabbitmq_version).and_return('3.4.0')
      expect(provider.class).to receive(:rabbitmq_running).and_return(true)
      expect(provider).to receive(:rabbitmqplugins).with('enable', 'foo')
      provider.create
    end
  end

  context 'with RabbitMQ version < 3.4.0' do
    it 'calls rabbitmqplugins to enable' do
      expect(provider.class).to receive(:rabbitmq_version).and_return('3.3.9')
      expect(provider.class).to receive(:rabbitmq_running).and_return(true)
      expect(provider).to receive(:rabbitmqplugins).with('enable', 'foo')
      provider.create
    end

    it 'calls rabbitmqplugins to enable with offline' do
      provider.resource[:mode] = :offline
      expect(provider.class).to receive(:rabbitmq_version).and_return('3.3.9')
      expect(provider.class).to receive(:rabbitmq_running).and_return(true)
      expect(provider).to receive(:rabbitmqplugins).with('enable', 'foo')
      provider.create
    end

    it 'calls rabbitmqplugins to enable with online' do
      provider.resource[:mode] = :online
      expect(provider.class).to receive(:rabbitmq_version).and_return('3.3.9')
      expect(provider.class).to receive(:rabbitmq_running).and_return(true)
      expect(provider).to receive(:rabbitmqplugins).with('enable', 'foo')
      provider.create
    end

    it 'calls rabbitmqplugins to enable with best' do
      provider.resource[:mode] = :best
      expect(provider.class).to receive(:rabbitmq_version).and_return('3.3.9')
      expect(provider.class).to receive(:rabbitmq_running).and_return(true)
      expect(provider).to receive(:rabbitmqplugins).with('enable', 'foo')
      provider.create
    end
  end

  it 'calls rabbitmqplugins to disable' do
    expect(provider).to receive(:rabbitmqplugins).with('disable', 'foo')
    provider.destroy
  end
end

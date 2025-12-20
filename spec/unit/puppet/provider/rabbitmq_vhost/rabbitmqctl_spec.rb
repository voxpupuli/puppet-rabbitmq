# frozen_string_literal: true

require 'spec_helper'

provider_class = Puppet::Type.type(:rabbitmq_vhost).provider(:rabbitmqctl)

describe provider_class do
  let(:resource) do
    Puppet::Type.type(:rabbitmq_vhost).new(
      ensure: :present,
      name: 'foo',
      description: 'foo description',
      default_queue_type: 'quorum',
      tags: %w[foo bar],
      provider: described_class.name
    )
  end

  let(:provider) { provider_class.new(resource) }
  let(:instance) { provider_class.instances.first }

  before do
    allow(provider_class).to receive(:supports_metadata?).and_return(true)
    allow(provider_class).to receive(:vhost_list).and_return(<<~EOT)
      foo\tFoo vhost\tquorum\t[foo, bar]
      bar\t\tclassic\t[]
    EOT
  end

  describe '#self.instances' do
    it 'returns all vhosts' do
      expect(provider_class.instances.size).to eq(2)
    end

    it 'parses vhost attributes correctly' do
      vhost = provider_class.instances.find { |p| p.name == 'foo' }

      expect(vhost.get(:ensure)).to eq(:present)
      expect(vhost.get(:description)).to eq('Foo vhost')
      expect(vhost.get(:default_queue_type)).to eq('quorum')
      expect(vhost.get(:tags)).to match_array(%w[foo bar])
    end
  end

  describe '#exists?' do
    it 'returns true for prefetched instance' do
      expect(instance.exists?).to be true
    end
  end

  describe '.prefetch' do
    it 'assigns prefetched provider to resource' do
      resources = { 'foo' => resource }

      provider_class.prefetch(resources)

      expect(resource.provider).to eq(instance)
    end
  end

  describe '#create' do
    it 'creates vhost with metadata' do
      expect(provider).to receive(:supports_metadata?).at_least(:once).and_return(true)
      expect(provider).to receive(:rabbitmqctl).with(
        'add_vhost',
        'foo',
        ['--description', 'foo description'],
        ['--default-queue-type', 'quorum'],
        ['--tags', 'foo,bar']
      )

      provider.create
    end

    it 'with RabbitMQ version <3.11.0 (no metadata support)' do
      expect(provider).to receive(:supports_metadata?).at_least(:once).and_return(false)
      expect(provider).to receive(:rabbitmqctl).with('add_vhost', 'foo')
      provider.create
    end
  end

  describe '#flush' do
    it 'updates vhost metadata in a single call' do
      provider.set(
        description: 'old description',
        tags: %w[oldtag1 oldtag2]
      )
      provider.description = 'new description'
      provider.tags = %w[tag1 tag2]

      expect(provider).to receive(:supports_metadata?).at_least(:once).and_return(true)
      expect(provider).to receive(:rabbitmqctl).with(
        'update_vhost_metadata',
        'foo',
        ['--description', 'new description'],
        ['--tags', 'tag1,tag2']
      )
      provider.flush
    end
  end

  describe '#destroy' do
    it 'deletes vhost' do
      expect(provider).to receive(:rabbitmqctl).with('delete_vhost', 'foo')
      provider.destroy
    end
  end
end

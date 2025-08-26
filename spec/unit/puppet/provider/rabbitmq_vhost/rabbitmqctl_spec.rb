# frozen_string_literal: true

require 'spec_helper'
describe Puppet::Type.type(:rabbitmq_vhost).provider(:rabbitmqctl) do
  let(:resource) do
    Puppet::Type::Rabbitmq_vhost.new(
      name: 'foo',
      description: 'foo description',
      default_queue_type: 'quorum',
      tags: %w[foo bar]
    )
  end
  let(:provider) { described_class.new(resource) }

  it 'matches vhost names' do
    expect(provider).to receive(:rabbitmqctl_list).with('vhosts').and_return(<<~EOT)
      Listing vhosts ...
      foo
      ...done.
    EOT
    expect(provider.exists?).to eq(true)
  end

  it 'does not match if no vhosts on system' do
    expect(provider).to receive(:rabbitmqctl_list).with('vhosts').and_return(<<~EOT)
      Listing vhosts ...
      ...done.
    EOT
    expect(provider.exists?).to eq(false)
  end

  it 'does not match if no matching vhosts on system' do
    expect(provider).to receive(:rabbitmqctl_list).with('vhosts').and_return(<<~EOT)
      Listing vhosts ...
      fooey
      ...done.
    EOT
    expect(provider.exists?).to eq(false)
  end

  context 'with RabbitMQ version <3.11.0 (no metadata support)' do
    it 'calls rabbitmqctl to create' do
      expect(provider).to receive(:supports_metadata?).at_least(:once).and_return(false)
      expect(provider).to receive(:rabbitmqctl).with('add_vhost', 'foo')
      provider.create
    end
  end

  context 'with RabbitMQ version >=3.11.0 (metadata support)' do
    it 'parses vhost list with valid metadata' do
      expect(provider.class).to receive(:supports_metadata?).at_least(:once).and_return(true)
      expect(provider.class).to receive(:vhost_list).and_return(<<~EOT)
        inventory		classic	[]
        /	Default virtual host	undefined	[]
        search		quorum	[]
        testing	My cool vhost	undefined	[tag1, tag2]
      EOT
      instances = provider.class.instances
      expect(instances.size).to eq(4)
      expect(instances.map do |prov|
        {
          name: prov.get(:name),
          description: prov.get(:description),
          default_queue_type: prov.get(:default_queue_type),
          tags: prov.get(:tags)
        }
      end).to eq(
        [
          {
            name: 'inventory',
            description: '',
            default_queue_type: 'classic',
            tags: []
          },
          {
            name: '/',
            description: 'Default virtual host',
            default_queue_type: :absent,
            tags: []
          },
          {
            name: 'search',
            description: '',
            default_queue_type: 'quorum',
            tags: []
          },
          {
            name: 'testing',
            description: 'My cool vhost',
            default_queue_type: :absent,
            tags: %w[tag1 tag2]
          }
        ]
      )
    end

    it 'throws error when parsing invalid vhost metadata' do
      expect(provider.class).to receive(:supports_metadata?).at_least(:once).and_return(true)
      expect(provider.class).to receive(:vhost_list).and_return(<<~EOT)
        inventory		undefined	[]
        /	Default virtual host	undefined
      EOT
      expect { print provider.class.instances }.to raise_error(Puppet::Error, %r{Cannot parse invalid vhost line: /	Default virtual host	undefined})
    end

    it 'calls rabbitmqctl to create with metadata' do
      expect(provider).to receive(:supports_metadata?).at_least(:once).and_return(true)
      expect(provider).to receive(:rabbitmqctl).with('add_vhost', 'foo', ['--description', 'foo description'], \
                                                     ['--default-queue-type', 'quorum'], ['--tags', 'foo,bar'])
      provider.create
    end

    it 'updates tags' do
      provider.set(tags: %w[tag1 tag2])
      expect(provider).to receive(:exists?).at_least(:once).and_return(true)
      expect(provider).to receive(:supports_metadata?).at_least(:once).and_return(true)
      expect(provider).to receive(:rabbitmqctl).with('update_vhost_metadata', 'foo', ['--tags', 'tag1,tag2'])
      provider.flush
    end

    it 'updates description' do
      provider.set(description: 'this is the new description')
      expect(provider).to receive(:exists?).at_least(:once).and_return(true)
      expect(provider).to receive(:supports_metadata?).at_least(:once).and_return(true)
      expect(provider).to receive(:rabbitmqctl).with('update_vhost_metadata', 'foo', ['--description', 'this is the new description'])
      provider.flush
    end
  end

  it 'calls rabbitmqctl to delete' do
    expect(provider).to receive(:rabbitmqctl).with('delete_vhost', 'foo')
    provider.destroy
  end
end

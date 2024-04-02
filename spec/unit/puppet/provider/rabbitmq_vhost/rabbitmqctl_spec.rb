# frozen_string_literal: true

require 'spec_helper'

describe Puppet::Type.type(:rabbitmq_vhost).provider(:rabbitmqctl) do
  let(:params) do
    {
      name: 'foo',
      description: 'foo description',
      default_queue_type: 'quorum',
      tags: %w[foo bar]
    }
  end
  let(:type_class) { Puppet::Type.type(:rabbitmq_vhost).provider(:rabbitmqctl) }
  let(:resource) { Puppet::Type.type(:rabbitmq_vhost).new(params) }
  let(:provider) { resource.provider }
  let(:instances) { type_class.instances }

  it 'matches vhost names' do
    allow(type_class).to receive(:rabbitmqctl_list).with('vhosts').and_return <<~EOT
      Listing vhosts ...
      foo
      ...done.
    EOT
    expect(provider.exists?).to be(true)
  end

  it 'does not match if no vhosts on system' do
    allow(type_class).to receive(:rabbitmqctl_list).with('vhosts').and_return <<~EOT
      Listing vhosts ...
      ...done.
    EOT
    expect(provider.exists?).to be(false)
  end

  it 'does not match if no matching vhosts on system' do
    allow(type_class).to receive(:rabbitmqctl_list).with('vhosts').and_return <<~EOT
      Listing vhosts ...
      fooey
      ...done.
    EOT
    expect(provider.exists?).to be(false)
  end

  context 'with RabbitMQ version <3.11.0 (no metadata support)' do
    it 'calls rabbitmqctl to create' do
      allow(type_class).to receive(:supports_metadata?).at_least(1).and_return false
      allow(type_class).to receive(:rabbitmqctl).with('add_vhost', 'foo')
      provider.create
    end
  end

  context 'with RabbitMQ version >=3.11.0 (metadata support)' do
    it 'parses vhost list with valid metadata' do
      allow(type_class).to receive(:supports_metadata?).at_least(1).and_return true
      allow(type_class).to receive(:vhost_list).and_return <<~EOT
        inventory		classic	[]
        /	Default virtual host	undefined	[]
        search		quorum	[]
        testing	My cool vhost	undefined	[tag1, tag2]
      EOT
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
      allow(type_class).to receive(:supports_metadata?).at_least(1).and_return true
      allow(type_class).to receive(:vhost_list).and_return <<~EOT
        inventory		undefined	[]
        /	Default virtual host	undefined
      EOT
      expect { print instances }.to raise_error(Puppet::Error, %r{Cannot parse invalid vhost line: /	Default virtual host	undefined})
    end

    it 'calls rabbitmqctl to create with metadata' do
      allow(type_class).to receive(:supports_metadata?).at_least(1).and_return true
      allow(type_class).to receive(:rabbitmqctl).with('add_vhost', 'foo', ['--description', 'foo description'], \
                                                      ['--default-queue-type', 'quorum'], ['--tags', 'foo,bar'])
      provider.create
    end

    it 'updates tags' do
      provider.set(tags: %w[tag1 tag2])
      allow(provider).to receive(:exists?).at_least(1).and_return true
      allow(provider).to receive(:supports_metadata?).at_least(1).and_return true
      allow(provider).to receive(:rabbitmqctl).with('update_vhost_metadata', 'foo', ['--tags', 'tag1,tag2'])
      provider.flush
    end

    it 'updates description' do
      provider.set(description: 'this is the new description')
      allow(provider).to receive(:exists?).at_least(1).and_return true
      allow(provider).to receive(:supports_metadata?).at_least(1).and_return true
      allow(provider).to receive(:rabbitmqctl).with('update_vhost_metadata', 'foo', ['--description', 'this is the new description'])
      provider.flush
    end
  end

  it 'calls rabbitmqctl to delete' do
    allow(type_class).to receive(:rabbitmqctl).with('delete_vhost', 'foo')
    provider.destroy
  end
end

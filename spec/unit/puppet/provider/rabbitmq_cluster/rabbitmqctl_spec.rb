# frozen_string_literal: true

require 'spec_helper'

describe Puppet::Type.type(:rabbitmq_cluster).provider(:rabbitmqctl) do
  let(:params) do
    {
      name: 'test_cluster',
      init_node: 'host1',
      provider: described_class.name,
    }
  end
  let(:type_class) { Puppet::Type.type(:rabbitmq_cluster).provider(:rabbitmqctl) }
  let(:resource) { Puppet::Type.type(:rabbitmq_cluster).new(params) }
  let(:provider) { resource.provider }

  describe '#exists?' do
    it {
      allow(type_class).to receive(:rabbitmqctl).with('-q', 'cluster_status').and_return(
        'Cluster name: test_cluster'
      )
      expect(provider.exists?).to be true
    }
  end

  describe '#create on every other node' do
    it 'joins a cluster or changes the cluster name' do
      allow(type_class).to receive(:rabbitmqctl).with('stop_app')
      allow(type_class).to receive(:rabbitmqctl).with('join_cluster', 'rabbit@host1', '--disc')
      allow(type_class).to receive(:rabbitmqctl).with('start_app')
      provider.create
    end
  end

  describe '#destroy' do
    it 'remove cluster setup' do
      allow(type_class).to receive(:rabbitmqctl).with('stop_app')
      allow(type_class).to receive(:rabbitmqctl).with('reset')
      allow(type_class).to receive(:rabbitmqctl).with('start_app')
      provider.destroy
    end
  end
end

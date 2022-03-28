# frozen_string_literal: true

require 'spec_helper'

provider_class = Puppet::Type.type(:rabbitmq_cluster).provider(:rabbitmqctl)
describe provider_class do
  let(:resource) do
    Puppet::Type::Rabbitmq_cluster.new(
      name: 'test_cluster',
      init_node: 'host1'
    )
  end
  let(:provider) { provider_class.new(resource) }

  describe '#exists?' do
    it {
      provider.expects(:rabbitmqctl).with('-q', 'cluster_status').returns(
        'Cluster name: test_cluster'
      )
      expect(provider.exists?).to be true
    }
  end

  describe '#create on every other node' do
    it 'joins a cluster or changes the cluster name' do
      provider.expects(:rabbitmqctl).with('stop_app')
      provider.expects(:rabbitmqctl).with('join_cluster', 'rabbit@host1', '--disc')
      provider.expects(:rabbitmqctl).with('start_app')
      provider.create
    end
  end

  describe '#destroy' do
    it 'remove cluster setup' do
      provider.expects(:rabbitmqctl).with('stop_app')
      provider.expects(:rabbitmqctl).with('reset')
      provider.expects(:rabbitmqctl).with('start_app')
      provider.destroy
    end
  end
end

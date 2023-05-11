# frozen_string_literal: true

require 'spec_helper'
describe Puppet::Type.type(:rabbitmq_cluster) do
  let(:rabbitmq_cluster) do
    Puppet::Type.type(:rabbitmq_cluster).new(name: 'test_cluster')
  end

  it 'accepts a cluster name' do
    rabbitmq_cluster[:name] = 'test_cluster'
    expect(rabbitmq_cluster[:name]).to eq('test_cluster')
  end

  it 'requires a name' do
    expect do
      Puppet::Type.type(:rabbitmq_cluster).new({})
    end.to raise_error(Puppet::Error, 'Title or name must be provided')
  end

  it 'check if init_node set to host1' do
    rabbitmq_cluster[:init_node] = 'host1'
    expect(rabbitmq_cluster[:init_node]).to eq('host1')
  end

  it 'check if local_node set to host1' do
    rabbitmq_cluster[:local_node] = 'host1'
    expect(rabbitmq_cluster[:local_node]).to eq('host1')
  end

  it 'local_node not set should default to undef' do
    rabbitmq_cluster[:init_node] = 'host1'
    expect(rabbitmq_cluster[:local_node]).to eq(:undef)
  end

  it 'try to set node_disc_type to ram' do
    rabbitmq_cluster[:node_disc_type] = 'ram'
    expect(rabbitmq_cluster[:node_disc_type]).to eq('ram')
  end

  it 'node_disc_type not set should default to disc' do
    rabbitmq_cluster[:name] = 'test_cluster'
    expect(rabbitmq_cluster[:node_disc_type]).to eq('disc')
  end
end

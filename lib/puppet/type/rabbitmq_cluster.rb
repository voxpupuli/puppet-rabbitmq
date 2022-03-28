# frozen_string_literal: true

Puppet::Type.newtype(:rabbitmq_cluster) do
  desc <<~DESC
    Native type for managing rabbitmq cluster

    @example Configure a cluster, rabbit_cluster
     rabbitmq_cluster { 'rabbit_cluster':
       init_node      => 'host1'
     }

    @example Optional parameter tags will set further rabbitmq tags like monitoring, policymaker, etc.
     To set the cluster name use cluster_name.
     rabbitmq_cluster { 'rabbit_cluster':
       init_node      => 'host1',
       node_disc_type => 'ram',
     }
  DESC

  ensurable do
    defaultto(:present)
    newvalue(:present) do
      provider.create
    end
    newvalue(:absent) do
      provider.destroy
    end
  end

  autorequire(:service) { 'rabbitmq-server' }

  newparam(:name, namevar: true) do
    desc 'The cluster name'
  end

  newparam(:init_node) do
    desc 'Name of which cluster node to join.'
    validate do |value|
      resource.validate_init_node(value)
    end
  end

  newparam(:node_disc_type) do
    desc 'Storage type of node, default disc.'
    newvalues(%r{disc|ram})
    defaultto('disc')
  end

  def validate_init_node(value)
    raise ArgumentError, 'init_node must be defined' if value.empty?
  end
end

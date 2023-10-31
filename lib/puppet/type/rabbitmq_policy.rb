# frozen_string_literal: true

Puppet::Type.newtype(:rabbitmq_policy) do
  desc <<~DESC
    Type for managing rabbitmq policies

    @example Create a rabbitmq_policy
     rabbitmq_policy { 'ha-all@myvhost':
       pattern    => '.*',
       priority   => 0,
       applyto    => 'all',
       definition => {
         'ha-mode'      => 'all',
         'ha-sync-mode' => 'automatic',
       },
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

  validate do
    raise('pattern parameter is required.') if self[:ensure] == :present && self[:pattern].nil?
    raise('definition parameter is required.') if self[:ensure] == :present && self[:definition].nil?
  end

  newparam(:name, namevar: true) do
    desc 'combination of policy@vhost to create policy for'
    newvalues(%r{^\S+@\S+$})
  end

  newproperty(:pattern) do
    desc 'policy pattern'
    validate do |value|
      resource.validate_pattern(value)
    end
  end

  newproperty(:applyto) do
    desc 'policy apply to'
    newvalue(:all)
    newvalue(:classic_queues)
    newvalue(:exchanges)
    newvalue(:queues)
    newvalue(:quorum_queues)
    newvalue(:streams)
    defaultto :all
  end

  newproperty(:definition) do
    desc 'policy definition'
    validate do |value|
      resource.validate_definition(value)
    end
    munge do |value|
      resource.munge_definition(value)
    end
  end

  newproperty(:priority) do
    desc 'policy priority'
    newvalues(%r{^\d+$})
    defaultto 0
  end

  autorequire(:rabbitmq_vhost) do
    [self[:name].split('@')[1]]
  end

  def validate_pattern(value)
    Regexp.new(value)
  rescue RegexpError
    raise ArgumentError, "Invalid regexp #{value}"
  end

  def validate_definition(definition)
    raise ArgumentError, 'Invalid definition' unless [Hash].include?(definition.class)

    definition.each do |k, v|
      if k == 'ha-params' && definition['ha-mode'] == 'nodes'
        raise ArgumentError, "Invalid definition, value #{v} for key #{k} is not an array" unless [Array].include?(v.class)
      else
        raise ArgumentError, "Invalid definition, value #{v} is not a string" unless [String].include?(v.class)
      end
    end
    if definition['ha-mode'] == 'exactly'
      ha_params = definition['ha-params']
      raise ArgumentError, "Invalid ha-params '#{ha_params}' for ha-mode 'exactly'" unless ha_params.to_i.to_s == ha_params
    end
    if definition.key? 'expires'
      expires_val = definition['expires']
      raise ArgumentError, "Invalid expires value '#{expires_val}'" unless expires_val.to_i.to_s == expires_val
    end
    if definition.key? 'message-ttl'
      message_ttl_val = definition['message-ttl']
      raise ArgumentError, "Invalid message-ttl value '#{message_ttl_val}'" unless message_ttl_val.to_i.to_s == message_ttl_val
    end
    if definition.key? 'max-length'
      max_length_val = definition['max-length']
      raise ArgumentError, "Invalid max-length value '#{max_length_val}'" unless max_length_val.to_i.to_s == max_length_val
    end
    if definition.key? 'max-length-bytes'
      max_length_bytes_val = definition['max-length-bytes']
      raise ArgumentError, "Invalid max-length-bytes value '#{max_length_bytes_val}'" unless max_length_bytes_val.to_i.to_s == max_length_bytes_val
    end
    if definition.key? 'shards-per-node'
      shards_per_node_val = definition['shards-per-node']
      raise ArgumentError, "Invalid shards-per-node value '#{shards_per_node_val}'" unless shards_per_node_val.to_i.to_s == shards_per_node_val
    end
    if definition.key? 'ha-sync-batch-size'
      ha_sync_batch_size_val = definition['ha-sync-batch-size']
      raise ArgumentError, "Invalid ha-sync-batch-size value '#{ha_sync_batch_size_val}'" unless ha_sync_batch_size_val.to_i.to_s == ha_sync_batch_size_val
    end
    if definition.key? 'delivery-limit'
      delivery_limit_val = definition['delivery-limit']
      raise ArgumentError, "Invalid delivery-limit value '#{delivery_limit_val}'" unless delivery_limit_val.to_i.to_s == delivery_limit_val
    end
    if definition.key? 'initial-cluster-size' # rubocop:disable Style/GuardClause
      initial_cluster_size_val = definition['initial-cluster-size']
      raise ArgumentError, "Invalid initial-cluster-size value '#{initial_cluster_size_val}'" unless initial_cluster_size_val.to_i.to_s == initial_cluster_size_val
    end
  end

  def munge_definition(definition)
    definition['ha-params'] = definition['ha-params'].to_i if definition['ha-mode'] == 'exactly'
    definition['expires'] = definition['expires'].to_i if definition.key? 'expires'
    definition['message-ttl'] = definition['message-ttl'].to_i if definition.key? 'message-ttl'
    definition['max-length'] = definition['max-length'].to_i if definition.key? 'max-length'
    definition['max-length-bytes'] = definition['max-length-bytes'].to_i if definition.key? 'max-length-bytes'
    definition['shards-per-node'] = definition['shards-per-node'].to_i if definition.key? 'shards-per-node'
    definition['ha-sync-batch-size'] = definition['ha-sync-batch-size'].to_i if definition.key? 'ha-sync-batch-size'
    definition['delivery-limit'] = definition['delivery-limit'].to_i if definition.key? 'delivery-limit'
    definition['initial-cluster-size'] = definition['initial-cluster-size'].to_i if definition.key? 'initial-cluster-size'
    definition
  end
end

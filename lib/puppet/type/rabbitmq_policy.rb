Puppet::Type.newtype(:rabbitmq_policy) do
  desc 'Type for managing rabbitmq policies'

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
    fail('pattern parameter is required.') if self[:ensure] == :present and self[:pattern].nil?
    fail('definition parameter is required.') if self[:ensure] == :present and self[:definition].nil?
  end

  newparam(:name, :namevar => true) do
    desc 'combination of policy@vhost to create policy for'
    newvalues(/^\S+@\S+$/)
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
    newvalue(:exchanges)
    newvalue(:queues)
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
    newvalues(/^\d+$/)
    defaultto 0
  end

  autorequire(:rabbitmq_vhost) do
    [self[:name].split('@')[1]]
  end

  def validate_pattern(value)
    begin
      Regexp.new(value)
    rescue RegexpError
      raise ArgumentError, "Invalid regexp #{value}"
    end
  end

  def validate_definition(definition)
    unless [Hash].include?(definition.class)
      raise ArgumentError, "Invalid definition"
    end
    definition.each do |k,v|
      unless [String].include?(v.class) || [Array].include?(v.class)
        raise ArgumentError, "Invalid definition, value #{v} is not a string or array"
      end
    end
    if definition['ha-mode'] == 'exactly'
      ha_params = definition['ha-params']
      unless ha_params.to_i.to_s == ha_params
        raise ArgumentError, "Invalid ha-params '#{ha_params}' for ha-mode 'exactly'"
      end
    end
    if definition.key? 'expires'
      expires_val = definition['expires']
      unless expires_val.to_i.to_s == expires_val
        raise ArgumentError, "Invalid expires value '#{expires_val}'"
      end
    end
    if definition.key? 'message-ttl'
      message_ttl_val = definition['message-ttl']
      unless message_ttl_val.to_i.to_s == message_ttl_val
        raise ArgumentError, "Invalid message-ttl value '#{message_ttl_val}'"
      end
    end
    if definition.key? 'max-length'
      max_length_val = definition['max-length']
      unless max_length_val.to_i.to_s == max_length_val
        raise ArgumentError, "Invalid max-length value '#{max_length_val}'"
      end
    end
    if definition.key? 'shards-per-node'
      shards_per_node_val = definition['shards-per-node']
      unless shards_per_node_val.to_i.to_s == shards_per_node_val
        raise ArgumentError, "Invalid shards-per-node value '#{shards_per_node_val}'"
      end
    end
  end

  def munge_definition(definition)
    if definition['ha-mode'] == 'exactly'
      definition['ha-params'] = definition['ha-params'].to_i
    end
    if definition.key? 'expires'
      definition['expires'] = definition['expires'].to_i
    end
    if definition.key? 'message-ttl'
      definition['message-ttl'] = definition['message-ttl'].to_i
    end
    if definition.key? 'max-length'
      definition['max-length'] = definition['max-length'].to_i
    end
    if definition.key? 'shards-per-node'
      definition['shards-per-node'] = definition['shards-per-node'].to_i
    end
    definition
  end
end

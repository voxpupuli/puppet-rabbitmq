# frozen_string_literal: true

# See below; these are variables that we want to auto-convert to integer
# values
CONVERT_TO_INT_VARS = %w[
  consumer-timeout
  delivery-limit
  expires
  ha-sync-batch-size
  initial-cluster-size
  max-length
  max-length-bytes
  message-ttl
  shards-per-node
].freeze

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
    desc 'Whether the resource should be present or absent'
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

    # Since this pattern is repeated, use a constant to track all the types
    # where we need to convert a string value to an unquoted integer explicitly
    definition.each do |k, v|
      raise ArgumentError, "Invalid #{k} value '#{v}'" if CONVERT_TO_INT_VARS.include?(k) && v.to_i.to_s != v
    end
  end

  def munge_definition(definition)
    definition['ha-params'] = definition['ha-params'].to_i if definition['ha-mode'] == 'exactly'

    # Again, use a list of types to convert vs. hard-coding each one
    definition.each do |k, v|
      definition[k] = v.to_i if CONVERT_TO_INT_VARS.include? k
    end

    definition
  end
end

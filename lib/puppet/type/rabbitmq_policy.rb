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
      unless [String].include?(v.class)
        raise ArgumentError, "Invalid definition"
      end
    end
  end
end

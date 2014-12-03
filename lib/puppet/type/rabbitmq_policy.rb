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

  newparam(:name, :namevar => true) do
    desc 'Name of policy'
    newvalues(/^\S+$/)
  end

  newproperty(:vhost) do
    desc 'name of vhost to add policy'
    newvalues(/^\S+$/)
  end

  newproperty(:pattern) do
    desc 'regexp representing policy pattern'
    validate do |value|
      resource.validate_policy_pattern(value)
    end
  end

  newproperty(:apply_to) do
    desc 'where the policy should be applied'
    newvalues(/^\S+$/)
  end

  newproperty(:priority) do
    desc 'policy priority'
    newvalue(/^\d+$/)
  end

  newproperty(:definition) do
    desc 'policy definition'
    newvalues(/^\S+$/)
  end

  # I may want to dissalow whitespace
  def validate_policy_pattern(value)
    begin
      Regexp.new(value)
    rescue RegexpError
      raise ArgumentError, "Invalid regexp #{value}"
    end
  end

end

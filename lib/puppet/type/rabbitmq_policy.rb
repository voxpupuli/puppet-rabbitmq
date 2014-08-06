Puppet::Type.newtype(:rabbitmq_policy) do
  desc 'Native type for managing rabbitmq policy'

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

  newparam(:vhost) do
    desc 'Vhost for policy'
    newvalues(/^\S+$/)
  end

  newparam(:match) do
    desc 'Regex match for policy'
  end

  newparam(:policy) do
    desc 'Policy to set'
  end

  validate do
    if self[:ensure] == :present and ! self[:policy] and ! self[:match]
      raise ArgumentError, 'must set policy and match' unless self[:policy] and self[:match]
    end
  end

end

Puppet::Type.newtype(:rabbitmq_user) do
  desc 'Native type for managing rabbitmq users'

  ensurable do
    defaultto(:present)
    newvalue(:present) do
      provider.create
    end
    newvalue(:absent) do
      provider.destroy
    end
  end

  newparam(:name, :namevar => true) do
    desc 'Name of user'
    newvalues(/^\S+$/)
  end

  # newproperty(:password) do
  newparam(:password) do
    desc 'User password to be set *on creation*'
  end

  newproperty(:tags, :array_matching => :all) do
    desc 'User tags'
  end

  validate do
    if self[:ensure] == :present and ! self[:password]
      raise ArgumentError, 'must set password when creating user' unless self[:password]
    end
  end

end

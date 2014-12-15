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

  autorequire(:service) { 'rabbitmq-server' }

  newparam(:name, :namevar => true) do
    desc 'Name of user'
    newvalues(/^\S+$/)
  end

  newproperty(:password) do
    desc 'User password to be set *on creation* and validated each run'
    def insync?(is)
      provider.check_password
    end
    def set(value)
      provider.change_password
    end
    def change_to_s(current, desired)
      "password has been changed"
    end
  end

  newproperty(:admin) do
    desc 'rather or not user should be an admin'
    newvalues(/true|false/)
    munge do |value|
      # converting to_s incase its a boolean
      value.to_s.to_sym
    end
    defaultto :false
  end

  newproperty(:tags, :array_matching => :all) do
    desc 'additional tags for the user'
  end

  validate do
    if self[:ensure] == :present and ! self[:password]
      raise ArgumentError, 'must set password when creating user' unless self[:password]
    end
  end

end

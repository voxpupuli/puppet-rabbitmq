Puppet::Type.newtype(:rabbitmq_user) do
  desc 'Native type for managing rabbitmq users'

  ensurable do
    defaultto(:present)
  end

  newparam(:name, :namevar => true) do
    desc 'Name of user'
    newvalues(/^\S+$/)
  end

  # newproperty(:password) do
  newparam(:password) do
    desc 'User password to be set *on creation*'
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

  validate do
    if resource[:ensure] == :present and ! resource[:password]
      raise ArgumentError, 'must set password when creating user' unless resource[:password]
    end
  end

end

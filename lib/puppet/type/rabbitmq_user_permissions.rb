# frozen_string_literal: true

Puppet::Type.newtype(:rabbitmq_user_permissions) do
  desc <<~DESC
    Type for managing rabbitmq user permissions

    @example Define some rabbitmq_user_permissions
     rabbitmq_user_permissions { 'dan@myvhost':
       configure_permission => '.*',
       read_permission      => '.*',
       write_permission     => '.*',
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
    desc 'combination of user@vhost to grant privileges to'
    newvalues(%r{^\S+@\S+$})
  end

  newproperty(:configure_permission) do
    desc 'regexp representing configuration permissions'
    validate do |value|
      resource.validate_permissions(value)
    end
  end

  newproperty(:read_permission) do
    desc 'regexp representing read permissions'
    validate do |value|
      resource.validate_permissions(value)
    end
  end

  newproperty(:write_permission) do
    desc 'regexp representing write permissions'
    validate do |value|
      resource.validate_permissions(value)
    end
  end

  autorequire(:rabbitmq_vhost) do
    [self[:name].split('@')[1]]
  end

  autorequire(:rabbitmq_user) do
    [self[:name].split('@')[0]]
  end

  def validate_permissions(value)
    Regexp.new(value)
  rescue RegexpError
    raise ArgumentError, "Invalid regexp #{value}"
  end
end

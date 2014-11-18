Puppet::Type.newtype(:rabbitmq_parameter) do
  desc 'Native type for managing rabbitmq parameters'

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
    desc 'Name of parameter'
    newvalues(/^\S+$/)
  end

  newparam(:vhost) do
    desc 'Virtual Host to apply this parameter against.'
    defaultto('/')
    newvalues(/^\/?(\S+)?$/)
  end

  newparam(:type) do
    desc 'Type of parameter to be set'
    newvalues(/^\S+$/)
  end

  newparam(:value) do
    desc 'Parameter value'
    newvalues(/^.*$/)
  end

  validate do
  end
  #
  # autorequire(:rabbitmq_vhost) do
  #   [self[:name].split('@')[1]]
  # end
  #
  # autorequire(:rabbitmq_user) do
  #   [self[:user]]
  # end

end

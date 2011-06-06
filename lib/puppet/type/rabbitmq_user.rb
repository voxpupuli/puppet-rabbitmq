Puppet::Type.newtype(:rabbitmq_user) do
  desc 'Native type for managing rabbitmq users'

  ensurable

  newparam(:name, :namevar => true) do
    desc 'Name of user'
    newvalues(/^\S+$/)
  end

  # newproperty(:password) do
  newparam(:password) do
    desc 'User password to be set *on creation*'
  end

  # TODO implement admin prop (may have version restictions)
end

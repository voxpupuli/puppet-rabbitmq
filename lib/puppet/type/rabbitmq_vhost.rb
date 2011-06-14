Puppet::Type.newtype(:rabbitmq_vhost) do
  desc 'manages rabbitmq vhosts'

  ensurable do
    defaultto(:present)
  end

  newparam(:name, :namevar => true) do
    'name of the vhost to add'
    newvalues(/^\S+$/)
  end

end

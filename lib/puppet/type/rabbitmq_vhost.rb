Puppet::Type.newtype(:rabbitmq_vhost) do
  desc 'manages rabbitmq vhosts'

  ensurable

  newparam(:name, :namevar => true) do
    'name of the vhost to add'
    newvalues(/^\S+$/)
  end

end

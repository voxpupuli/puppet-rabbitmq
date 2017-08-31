Puppet::Type.newtype(:rabbitmq_vhost) do
  desc 'manages rabbitmq vhosts'

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
    desc 'The name of the vhost to add'
    newvalues(%r{^\S+$})
  end
end

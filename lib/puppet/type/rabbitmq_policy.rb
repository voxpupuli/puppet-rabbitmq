# rabbitmq_policy {'foo':
#   vhost => '/'
#   apply_to => 'queues',
#   pattern => '^mirror.*',
#   priority => 0,
#   value => '{ "ha-mode" : "all" }'
# }
Puppet::Type.newtype(:rabbitmq_policy) do
  desc 'Native type for managing rabbitmq policies'

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
    desc 'Name of policy'
    newvalues(/^\S+$/)
  end

  newparam(:vhost) do
    desc 'Virtual Host to apply this parameter against.'
    defaultto('/')
    newvalues(/^\/?(\S+)?$/)
  end

  newparam(:apply_to) do
    desc 'Thing to apply the policy to. Valid values are "exchanges", "queues"'
    newvalues(/^\S+$/)
  end

  newparam(:pattern) do
    desc 'Wildcard pattern that will apply this policy to things'
    newvalues(/^.*$/)
  end

  newparam(:definition) do
    newvalues(/^.*$/)
  end

  newparam(:priority) do
    defaultto(0)
    newvalues(/^\d+$/)
  end

  validate do
  end

end

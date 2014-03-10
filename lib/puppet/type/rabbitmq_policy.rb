require 'rubygems' if RUBY_VERSION < '1.9.0'
require 'json'

Puppet::Type.newtype(:rabbitmq_policy) do
  desc 'Native type for managing policies for rabbitmq'

  ensurable

  newparam(:name, :namevar => true) do
    desc 'Name of policy'
    newvalues(/^[\w\w-]+$/)
  end

  newproperty(:vhost) do
    desc 'The name of the rabbitmq vhost this policy applies to'
    defaultto '/'
  end

  newproperty(:pattern) do
    desc 'The pattern for queues / exchanges which this policy matches'
  end

  newproperty(:priority) do
    desc 'The priority for this policy'
    newvalues(/^\d+$/)
    defaultto '0'
  end

  newproperty(:apply_to) do
    desc 'What to apply this policy to'
    newvalues(/^(exchanges|queues)$/) # FIXME - both?
  end

  newproperty(:data) do
    desc 'Hash of data for the policy'
    defaultto {}
  end

  autorequire(:rabbitmq_vhost) do
    [self[:vhost]]
  end
end


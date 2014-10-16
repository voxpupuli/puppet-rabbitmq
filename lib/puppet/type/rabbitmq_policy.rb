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
    newvalues(/^[\w\/-]+$/)
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
    newvalues(/^(exchanges|queues|all)$/)
    defaultto 'all'
  end

  newproperty(:definition) do
    desc 'Hash of definition data for the policy'
    validate do |value|
      unless value.is_a?(Hash) and value.length > 0
        raise ArgumentError, 'definition must be a non-empty Hash'
      end
    end
  end

  autorequire(:rabbitmq_vhost) do
    [self[:vhost]]
  end
end

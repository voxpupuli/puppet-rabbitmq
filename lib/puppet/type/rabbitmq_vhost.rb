# frozen_string_literal: true

Puppet::Type.newtype(:rabbitmq_vhost) do
  desc <<~DESC
    Native type for managing rabbitmq vhosts

    @example query all current vhosts
     $ puppet resource rabbitmq_vhost`

    @example Create a rabbitmq_vhost
     rabbitmq_vhost { 'myvhost':
       ensure             => present,
       description        => 'myvhost description',
       tags               => ['tag1', 'tag2'],
       default_queue_type => 'quorum',
     }
  DESC

  ensurable do
    desc 'Whether the resource should be present or absent'
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

  newproperty(:description) do
    desc 'A description of the vhost'
  end

  newproperty(:default_queue_type) do
    desc 'The default queue type for queues in this vhost'
    newvalues(:classic, :quorum, :stream)
    munge(&:to_s)
  end

  newproperty(:tags, array_matching: :all) do
    desc 'additional tags for the vhost'
    validate do |value|
      raise ArgumentError, "Invalid tag: #{value.inspect}" unless value =~ %r{^\S+$}
    end
    defaultto []
  end
end

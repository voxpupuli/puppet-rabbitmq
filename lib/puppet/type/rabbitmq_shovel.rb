require 'puppet/parameter/boolean'
Puppet::Type.newtype(:rabbitmq_shovel) do
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

  newparam(:src_uris) do
    desc 'Type of parameter to be set'
    newvalues(/^\S+$/)
  end

  newparam(:dst_uris) do
    desc 'Type of parameter to be set'
    newvalues(/^\S+$/)
  end

  newparam(:src_exchange) do
    desc 'Source exchange'
    newvalues(/^.*$/)
  end

  newparam(:src_exchange_key) do
    desc 'Source exchange key'
    newvalues(/^.*$/)
  end

  newparam(:dst_exchange) do
    desc 'Destination exchange key'
    newvalues(/^.*$/)
  end

  newparam(:add_forward_headers,
           :boolean => true,
           :parent => Puppet::Parameter::Boolean)

  newparam(:ack_mode) do
    defaultto('on-confirm')
  end


  newparam(:delete_after) do
    defaultto('never')
  end

  validate do
  end


end

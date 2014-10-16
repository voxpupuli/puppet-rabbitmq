require 'rubygems' if RUBY_VERSION < '1.9.0'
require 'json'

Puppet::Type.newtype(:rabbitmq_federation_upstreamset) do
  desc 'Native type for managing sets of upstreams for rabbitmq federation'

  ensurable

  newparam(:name, :namevar => true) do
    desc 'Name of federation upstream set'
    newvalues(/^[\w\w-]+$/)
  end

  newparam(:vhost) do
    desc 'Vhost for federation upstream'
    newvalues(/^[\w\/-]+$/)
    defaultto '/'
  end

  autorequire(:rabbitmq_vhost) do
    [self[:vhost]]
  end

  newproperty(:upstreams, :array_matching => :all) do
    desc 'A list of the upstreams which comprise this upstream set'
    validate do |value|
      if 'all' == value
        raise ArgumentError, 'TxihHe upstream set named "all" cannot be configured as it is implicit'
      elsif !(value =~ /^[\w\w-]+$/)
        raise ArgumentError, 'No spaces allowed in upstreams'
      end
    end
  end
end

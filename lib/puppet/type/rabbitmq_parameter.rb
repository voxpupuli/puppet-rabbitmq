require 'rubygems' if RUBY_VERSION < '1.9.0'
require 'json'

Puppet::Type.newtype(:rabbitmq_parameter) do
  desc 'Native type for managing policies for rabbitmq'

  ensurable

  def self.title_patterns
    [
      [
        /^(\S+)\s(\S+)\s(\S+)$/,
        [
          [:vhost, lambda{|x| x} ],
          [:component, lambda{|x| x} ],
          [:name, lambda{|x| x} ]
        ]
      ]
    ]
  end

  newparam(:name, :namevar => true) do
    desc 'Name of parameter, should be of the form: vhost component_name name'
    newvalues(/^[\w\w-]+$/)
  end

  newparam(:vhost, :namevar => true) do
    desc 'Vhost for parameter'
    newvalues(/^[\w\/-]+$/)
    defaultto '/'
  end

  newparam(:component, :namevar => true) do
    desc 'Component for parameter'
    # The federation classes in this module have better validation and defaults
    # and should be used when appropriate otherwise errors can occur in the prefetch
    # method of those providers
    validate do |value|
      unless value =~ /^(?!federation)[\w-]+$/
        raise ArgumentError, 'Component invalid. For federation support use rabbitmq_federation_upstream or rabbitmq_federation_upstreamset classes.'
      end
    end
  end

  newproperty(:value) do
    desc 'Hash value for the parameter data'
    validate do |value|
      unless value.is_a?(Hash) and value.length > 0
        raise ArgumentError, 'value must be a non-empty Hash'
      end
    end
  end

  autorequire(:rabbitmq_vhost) do
    [self[:vhost]]
  end
end

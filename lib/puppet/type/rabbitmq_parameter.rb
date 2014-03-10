require 'rubygems' if RUBY_VERSION < '1.9.0'
require 'json'

Puppet::Type.newtype(:rabbitmq_parameter) do
  desc 'Native type for managing policies for rabbitmq'

  ensurable

  newparam(:name, :namevar => true) do
    desc 'Name of parameter, should be of the form: vhost component_name name'
    newvalues(/^\S+\s+\S+\s+\S+$/)
  end

  autorequire(:rabbitmq_vhost) do
    [self[:name].split(/\s+/)[0]]
  end

  newproperty(:value) do
    desc 'The value for the parameter data'
  end
end


# frozen_string_literal: true

Puppet::Type.newtype(:rabbitmq_parameter) do
  desc <<~DESC
    Type for managing rabbitmq parameters

    @example Create some rabbitmq_parameter resources
       rabbitmq_parameter { 'documentumShovel@/':
         component_name => '',
         value          => {
             'src-uri'    => 'amqp://',
             'src-queue'  => 'my-queue',
             'dest-uri'   => 'amqp://remote-server',
             'dest-queue' => 'another-queue',
         },
       }
       rabbitmq_parameter { 'documentumFed@/':
         component_name => 'federation-upstream',
         value          => {
             'uri'     => 'amqp://myserver',
             'expires' => '360000',
         },
       }
       rabbitmq_parameter { 'documentumShovelNoMunging@/':
         component_name => '',
         value          => {
             'src-uri'    => 'amqp://',
             'src-exchange'  => 'my-exchange',
             'src-exchange-key' => '6',
             'src-queue'  => 'my-queue',
             'dest-uri'   => 'amqp://remote-server',
             'dest-exchange' => 'another-exchange',
         },
         autoconvert   => false,
       }
  DESC

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

  validate do
    raise('component_name parameter is required.') if self[:ensure] == :present && provider.component_name.nil?
    raise('value parameter is required.') if self[:ensure] == :present && provider.value.nil?
  end

  newparam(:name, namevar: true) do
    desc 'combination of name@vhost to set parameter for'
    newvalues(%r{^\S+@\S+$})
  end

  newproperty(:component_name) do
    desc 'The component_name to use when setting parameter, eg: shovel or federation'
    validate do |value|
      resource.validate_component_name(value)
    end
  end

  newparam(:autoconvert) do
    desc 'whether numeric strings from `value` should be converted to int automatically'
    newvalues(:true, :false)
    defaultto(:true)
  end

  newproperty(:value) do
    desc 'A hash of values to use with the component name you are setting'
    validate do |value|
      resource.validate_value(value)
    end
    munge do |value|
      resource.munge_value(value)
    end
  end

  autorequire(:rabbitmq_vhost) do
    [self[:name].split('@')[1]]
  end

  def set_parameters(hash) # rubocop:disable Style/AccessorMethodName
    # Hack to ensure :autoconvert is initialized before :value
    self[:autoconvert] = hash[:autoconvert] if hash.key?(:autoconvert)
    super
  end

  def validate_component_name(value)
    raise ArgumentError, 'component_name must be defined' if value.empty?
  end

  def validate_value(value)
    raise ArgumentError, 'Invalid value' unless [Hash].include?(value.class)

    value.each do |_k, v|
      raise ArgumentError, 'Invalid value' unless [String, TrueClass, FalseClass, Array].include?(v.class)
    end
  end

  def munge_value(value)
    return value if value(:autoconvert) == :false

    value.each do |k, v|
      value[k] = v.to_i if v =~ %r{\A[-+]?[0-9]+\z}
    end
    value
  end
end

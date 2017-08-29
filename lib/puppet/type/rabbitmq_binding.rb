Puppet::Type.newtype(:rabbitmq_binding) do
  desc 'Native type for managing rabbitmq bindings'

  ensurable do
    defaultto(:present)
    newvalue(:present) do
      provider.create
    end
    newvalue(:absent) do
      provider.destroy
    end
  end

  # Match patterns without '@' as arbitrary names; match patterns with
  # src@destination@vhost to their named params for backwards compatibility.
  def self.title_patterns
    [
      [
        %r{(^([^@]*)$)}m,
        [
          [:name]
        ]
      ],
      [
        %r{^((\S+)@(\S+)@(\S+))$}m,
        [
          [:name],
          [:source],
          [:destination],
          [:vhost]
        ]
      ]
    ]
  end

  newparam(:name) do
    desc 'resource name, either source@destination@vhost or arbitrary name with params'

    isnamevar
  end

  newproperty(:source) do
    desc 'source of binding'

    newvalues(%r{^\S+$})
    isnamevar
  end

  newproperty(:destination) do
    desc 'destination of binding'

    newvalues(%r{^\S+$})
    isnamevar
  end

  newproperty(:vhost) do
    desc 'vhost'

    newvalues(%r{^\S+$})
    defaultto('/')
    isnamevar
  end

  newproperty(:routing_key) do
    desc 'binding routing_key'

    newvalues(%r{^\S*$})
    isnamevar
  end

  newproperty(:destination_type) do
    desc 'binding destination_type'
    newvalues(%r{queue|exchange})
    defaultto('queue')
  end

  newproperty(:arguments) do
    desc 'binding arguments'
    defaultto {}
    validate do |value|
      resource.validate_argument(value)
    end
  end

  newparam(:user) do
    desc 'The user to use to connect to rabbitmq'
    defaultto('guest')
    newvalues(%r{^\S+$})
  end

  newparam(:password) do
    desc 'The password to use to connect to rabbitmq'
    defaultto('guest')
    newvalues(%r{\S+})
  end

  autorequire(:rabbitmq_vhost) do
    setup_autorequire('vhost')
  end

  autorequire(:rabbitmq_exchange) do
    setup_autorequire('exchange')
  end

  autorequire(:rabbitmq_queue) do
    setup_autorequire('queue')
  end

  autorequire(:rabbitmq_user) do
    [self[:user]]
  end

  autorequire(:rabbitmq_user_permissions) do
    [
      "#{self[:user]}@#{self[:source]}",
      "#{self[:user]}@#{self[:destination]}"
    ]
  end

  def setup_autorequire(type)
    destination_type = value(:destination_type)
    if type == 'exchange'
      rval = ["#{self[:source]}@#{self[:vhost]}"]
      if destination_type == type
        rval.push("#{self[:destination]}@#{self[:vhost]}")
      end
    else
      rval = if destination_type == type
               ["#{self[:destination]}@#{self[:vhost]}"]
             else
               []
             end
    end
    rval
  end

  def validate_argument(argument)
    unless [Hash].include?(argument.class)
      raise ArgumentError, 'Invalid argument'
    end
  end

  # Validate that we have both source and destination now that these are not
  # necessarily only coming from the resource title.
  validate do
    unless self[:source] && self[:destination]
      raise ArgumentError, 'Source and destination must both be defined.'
    end
  end
end

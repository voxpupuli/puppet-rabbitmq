# frozen_string_literal: true

Puppet::Type.newtype(:rabbitmq_user) do
  desc <<~DESC
    Native type for managing rabbitmq users

    @example query all current users
     $ puppet resource rabbitmq_user

    @example Configure a user, dan
     rabbitmq_user { 'dan':
       admin    => true,
       password => 'bar',
     }

    @example Optional parameter tags will set further rabbitmq tags like monitoring, policymaker, etc.
     To set the administrator tag use admin-flag.
     rabbitmq_user { 'dan':
       admin    => true,
       password => 'bar',
       tags     => ['monitoring', 'tag1'],
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

  newparam(:name, namevar: true) do
    desc 'Name of user'
    newvalues(%r{^\S+$})
  end

  newproperty(:password) do
    desc 'User password to be set *on creation* and validated each run'
    def insync?(_is)
      provider.check_password(should)
    end

    def change_to_s(_current, _desired)
      'password has been changed'
    end

    def is_to_s(_value)
      '[old password redacted]'
    end

    def should_to_s(_value)
      '[new password redacted]'
    end
  end

  newproperty(:admin) do
    desc 'whether or not user should be an admin'
    newvalues(%r{true|false})
    munge do |value|
      # converting to_s in case its a boolean
      value.to_s.to_sym
    end
    defaultto :false
  end

  newproperty(:tags, array_matching: :all) do
    desc 'additional tags for the user'
    validate do |value|
      raise ArgumentError, "Invalid tag: #{value.inspect}" unless value =~ %r{^\S+$}

      raise ArgumentError, 'must use admin property instead of administrator tag' if value == 'administrator'
    end
    defaultto []

    def insync?(is)
      is.sort == should.sort
    end

    def should_to_s(value)
      Array(value)
    end
  end
end

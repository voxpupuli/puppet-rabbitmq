Puppet::Type.newtype(:rabbitmq_erlang_cookie) do
  desc 'Type to manage the rabbitmq erlang cookie securely'

  newparam(:path, :namevar => true)

  validate do
    # This does pre-validation on the content property and force parameter.
    # The intent is to simulate the prior behavior to the invention of this
    # type (see https://github.com/puppetlabs/puppetlabs-rabbitmq/blob/4.1.0/manifests/config.pp#L87-L117)
    # where validation occurs before the catalog starts being applied.
    # This prevents other resources from failing after attempting to apply
    # this resource and having it fail due to the force parameter being
    # set to false.
    is = (File.read(self[:path]) if File.exists?(self[:path])) || ''
    should = self[:content]
    failstring = 'The current erlang cookie needs to change. In order to do this the RabbitMQ database needs to be wiped. Please set force => true to allow this tohappen automatically.'
    fail(failstring) if (is != should && self[:force] != :true)
  end

  newproperty(:content) do
    desc 'Content of cookie'
    newvalues(/^\S+$/)
    def change_to_s(current, desired)
      "The rabbitmq erlang cookie was changed"
    end
  end

  newparam(:force) do
    defaultto(:false)
    newvalues(:true, :false)
  end

  newparam(:service_name) do
    newvalues(/^\S+$/)
  end
end

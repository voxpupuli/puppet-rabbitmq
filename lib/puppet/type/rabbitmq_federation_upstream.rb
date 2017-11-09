require 'rubygems' if RUBY_VERSION < '1.9.0'
require 'json'

Puppet::Type.newtype(:rabbitmq_federation_upstream) do
  desc 'Native type for managing upstreams for rabbitmq federation'

  ensurable

  newparam(:name, :namevar => true) do
    desc 'Name of federation upstream'
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

  newproperty(:uri, :array_matching => :all) do
    desc 'The uri for the server to connect to'
    newvalues(/^amqps?:\/\/\S+$/)
  end

  newproperty(:expires) do
    desc 'Time in milliseconds that the upstream should remember about this node for. After this time all upstream state will be removed. Leave this blank to mean "forever"'
    newvalues(/^\d+$/)
  end

  newproperty(:message_ttl) do
    desc 'Time in milliseconds that undelivered messages should be held upstream when there is a network outage or backlog. Leave this blank to mean "forever"'
    newvalues(/^\d+$/)
  end

  newproperty(:max_hops) do
    desc 'Maximum number of federation links that messages can traverse before being dropped. Defaults to 1 if not set.'
    newvalues(/^\d+$/)
    defaultto '1'
  end

  newproperty(:prefetch_count) do
    desc 'Maximum number of unacknowledged messages that may be in flight over a federation link at one time. Defaults to 1000 if not set.'
    newvalues(/^\d+$/)
    defaultto '1000'
  end

  newproperty(:reconnect_delay) do
    desc 'Time in seconds to wait after a network link goes down before attempting reconnection. Defaults to 1 if not set.'
    newvalues(/^\d+$/)
    defaultto '1'
  end

  newproperty(:ack_mode) do
    desc 'on-confirm (default), on-publish or no-ack'
    newvalues('on-confirm')
    newvalues('on-publish')
    newvalues('no-ack')
    defaultto 'on-confirm'
  end

  newproperty(:trust_user_id) do
    desc 'Set "Yes" to preserve the "user-id" field across a federation link, even if the user-id does not match that used to republish the message. Set to "No" to clear the "user-id" field when messages are federated. Only set this to "Yes" if you trust the upstream broker not to forge user-ids'
    newvalues(true)
    newvalues(false)
    defaultto :false
  end
end

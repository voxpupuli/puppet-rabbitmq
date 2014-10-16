Puppet::Type.type(:rabbitmq_federation_upstream).provide(:rabbitmqctl) do
  if Puppet::PUPPETVERSION.to_f < 3
    commands :rabbitmqctl => 'rabbitmqctl'
  else
     has_command(:rabbitmqctl, 'rabbitmqctl') do
       environment :HOME => "/tmp"
     end
  end

  mk_resource_methods
  defaultfor :feature => :posix

  def to_bool(val)
    return true if val == true || val == :true || val =~ (/(true|t|yes|y|1)$/i)
    return false if val == false || val == :false || val.blank? || val =~ (/(false|f|no|n|0)$/i)
    raise ArgumentError.new("invalid value for Boolean: \"#{val}\"")
  end

  def self.bool_to_sym(val)
    return :true if val == true || val == :true || val =~ (/(true|t|yes|y|1)$/i)
    return :false if val == false || val == :false || val.blank? || val =~ (/(false|f|no|n|0)$/i)
    raise ArgumentError.new("invalid value for Boolean: \"#{val}\"")
  end

  def self.instances
    rabbitmqctl('list_vhosts').split(/\n/)[1..-2].collect do |vhost|
      rabbitmqctl('list_parameters', '-p', vhost).split(/\n/).select { |line| line =~ /^federation-upstream\s+/ }.collect do |line|
        if line =~ /^\S+\s+(\S+)\s+(\S+)$/
          data = JSON.parse($2)
          new(:name => $1, :ensure => :present, :vhost => vhost, :uri => data['uri'], :expires => data['expires'].to_s, :message_ttl => data['message-ttl'].to_s, :ack_mode => data['ack-mode'], :trust_user_id => bool_to_sym(data['trust-user-id']), :prefetch_count => data['prefetch-count'].to_s, :max_hops => data['max-hops'].to_s, :reconnect_delay => data['reconnect-delay'].to_s)
        else
          raise Puppet::Error, "Cannot parse invalid federation-upstream line: #{line}"
        end
      end
    end.flatten
  end
  def self.prefetch(resources)
    instances.each do |provider|
      if resource = resources[provider.name] then
        resource.provider = provider
      end
    end
  end

  def create
    data = { 'uri' => resource[:uri], 'expires' => resource[:expires].to_i, 'message-ttl' => resource[:message_ttl].to_i, 'ack-mode' => resource[:ack_mode], 'trust-user-id' => to_bool(resource[:trust_user_id]), 'prefetch-count' => resource[:prefetch_count].to_i, 'max-hops' => resource[:max_hops].to_i, 'reconnect-delay' => resource[:reconnect_delay].to_i}
    rabbitmqctl('set_parameter', 'federation-upstream', resource[:name], data.to_json, '-p', resource[:vhost])
  end

  def destroy
    rabbitmqctl('clear_parameter', '-p', resource[:vhost], 'federation-upstream', resource[:name])
    @property_hash = {}  # used in conjunction with flush to avoid calling non-indempotent destroy twice
  end

  def exists?
    @property_hash[:ensure] == :present
  end

  def flush
    # flush is used purely in an update capacity
    # @property_hash is tested to avoid calling non-indempotent destroy twice
    if @property_hash == {}
      Puppet.debug 'hash empty - instance does not exist on system'
    elsif self.exists?
      self.create
    else
      self.destroy
    end
  end
end

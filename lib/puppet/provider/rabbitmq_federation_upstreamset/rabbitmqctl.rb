Puppet::Type.type(:rabbitmq_federation_upstreamset).provide(:rabbitmqctl) do
  if Puppet::PUPPETVERSION.to_f < 3
    commands :rabbitmqctl => 'rabbitmqctl'
  else
     has_command(:rabbitmqctl, 'rabbitmqctl') do
       environment :HOME => "/tmp"
     end
  end

  mk_resource_methods
  defaultfor :feature => :posix

  def self.instances
    rabbitmqctl('list_vhosts').split(/\n/)[1..-2].collect do |vhost|
      rabbitmqctl('list_parameters', '-p', vhost).split(/\n/).select { |line| line =~ /^federation-upstream-set/ }.collect do |line|
        if line =~ /^\S+\s+(\S+)\s+(\S+)$/
          names = JSON.parse($2).collect { |data| data['upstream'] }
          new(:name => $1, :ensure => :present, :vhost => vhost, :upstreams => names)
        else
          raise Puppet::Error, "Cannot parse invalid federation-upstream-set line: #{line}"
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
    data = resource[:upstreams].map { |name| { 'upstream' => name } }
    rabbitmqctl('set_parameter', '-p', resource[:vhost], 'federation-upstream-set', resource[:name], data.to_json)
  end

  def destroy
    rabbitmqctl('clear_parameter', '-p', resource[:vhost], 'federation-upstream-set', resource[:name])
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

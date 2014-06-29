Puppet::Type.type(:rabbitmq_parameter).provide(:rabbitmqctl) do
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
      rabbitmqctl('list_parameters', '-p', vhost).split(/\n/)[1..-2].collect do |line|
        # federation  local-username  "federation"
        if line =~ /^(\S+)\s+(\S+)\s+(\S+)$/
          new(:name => "#{vhost} #{$1} #{$2}", :ensure => :present, :value => $3)
        else
          raise Puppet::Error, "Cannot parse invalid user line: #{line}"
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
    data = resource[:name].split(/\s+/)
    rabbitmqctl('set_parameter', data[1], data[2], resource[:value], '-p', data[0])
  end

  def destroy
    data = resource[:name].split(/\s+/)
    rabbitmqctl('clear_parameter', data[1], data[2], '-p', data[0])
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

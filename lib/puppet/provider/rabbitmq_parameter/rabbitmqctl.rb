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
      # Federation should be handled by the dedicated federation classes to avoid errors
      rabbitmqctl('list_parameters', '-p', vhost).split(/\n/)[1..-2].select { |line| line =~ /^(?!federation)/ }.collect do |line|
        if line =~ /^(\S+)\s+(\S+)\s+(\S+)$/
          new(:name => $2, :ensure => :present, :vhost => vhost, :component => $1, :value => JSON.parse($3))
        else
          raise Puppet::Error, "Cannot parse invalid parameter line: #{line}"
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
    rabbitmqctl('set_parameter', resource[:component], resource[:name], resource[:value].to_json, '-p', resource[:vhost])
  end

  def destroy
    rabbitmqctl('clear_parameter', resource[:component], resource[:name], '-p', resource[:vhost])
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

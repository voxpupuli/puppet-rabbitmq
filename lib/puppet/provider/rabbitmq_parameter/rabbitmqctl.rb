Puppet::Type.type(:rabbitmq_parameter).provide(:rabbitmqctl) do

  mk_resource_methods

  if Puppet::PUPPETVERSION.to_f < 3
    commands :rabbitmqctl => 'rabbitmqctl'
  else
     has_command(:rabbitmqctl, 'rabbitmqctl') do
       environment :HOME => "/tmp"
     end
  end


  def self.get_vhosts
    vhosts = Array.new
    rabbitmqctl('list_vhosts', '-q').split(/\n/).each do |line|
      if line =~ /^(.*)$/
        vhosts << $1
      else
        raise Puppet::Error, "Cannot parse vhost line: #{line}"
      end
    end
    return vhosts
  end

  def self.get_parameters
    # set_parameter [-p <vhostpath>] <component_name> <name> <value>
    parameters = Array.new
    self.get_vhosts.each do |vhost|
      output = rabbitmqctl('list_parameters', "-q", "-p", vhost).split(/\n/)
      output.each do |line|

        if line =~ /^(\S+)\s+(\S+)\s+(.*)$/ then
          param = {}
          param[:type] = $1
          param[:name] = $2
          param[:value] = $3
          param[:vhost] = vhost
          parameters << param
        else
          raise  Puppet::Error, "Cannot parse list_parameters line: #{line}"
        end
      end
    end
    Puppet.debug "RabbitMQ parameters: #{parameters.inspect}"
    parameters
  end

  def self.instances
    self.get_parameters.collect do |param|
      new(:name => param[:name],
          :vhost => param[:vhost],
          :type => param[:type],
          :value => param[:value])
    end
  end

  def create_parameter(resource)
    rabbitmqctl('set_parameter',
                "-p",
                resource[:vhost],
                resource[:type],
                resource[:name],
                resource[:value])
  end

  def destroy_parameter(resource)
    rabbitmqctl('clear_parameter',
                "-p",
                resource[:vhost],
                resource[:type],
                resource[:name])
  end

  def parameter_exists(resource)
    output = rabbitmqctl('list_parameters', '-q', '-p', resource[:vhost])
    output.split(/\n/).each do |line|
      if line =~ /^(\S+)\s+(\S+)\s+(.*)$/ then
        if $2 == resource[:name] && (resource[:value] == nil || $3 == resource[:value].gsub(/\s+/, "").strip)
          return true
        end
      end
    end
    return false
  end

  def create
    create_parameter(resource)
  end

  def exists?
    parameter_exists(resource)
  end

  def destroy
    destroy_parameter(resource)
  end

  def self.prefetch(resources)
    instances.each do |prov|
      if resource = resources[prov.name]
        resource.provider = prov
      end
    end
  end

  def set_parameter
      if @property_flush[:ensure] == :absent
        self.destroy_parameter(resource[:vhost], resource[:name])
        return
      end
      create_parameter(resource)
  end
end

require 'json'

Puppet::Type.type(:rabbitmq_policy).provide(:rabbitmqctl) do

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

  def self.get_policies
    # set_policy [-p <vhostpath>] [--priority <priority>] [--apply-to <apply-to>]
    # <name> <pattern>  <definition>
    parameters = Array.new
    self.get_vhosts.each do |vhost|
      output = rabbitmqctl('list_policies', '-q', "-p", vhost).split(/\n/)
      output.each do |line|

        if line =~ /^(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\{.*\})\s+(\S+)$/ then
          definition_str = $5
          definition_obj = JSON.load(definition_str)
          param = {}
          param[:name] = $2
          param[:apply_to] = $3
          param[:pattern] = $4
          param[:definition] = definition_obj
          param[:priority] = $6
          param[:vhost] = vhost

          parameters << param
        else
          raise  Puppet::Error, "Cannot parse list_parameters line: #{line}"
        end
      end
    end
    Puppet.debug "RabbitMQ policies: #{parameters.inspect}"
    parameters
  end

  def self.instances
    self.get_policies.collect do |param|
      new(param)
    end
  end

  def create_policy(resource)
    # set_policy [-p <vhostpath>] [--priority <priority>] [--apply-to <apply-to>]
    # <name> <pattern>  <definition>
    rabbitmqctl('set_policy',
                "-p",
                resource[:vhost],

                "--priority",
                resource[:priority],

                "--apply-to",
                resource[:apply_to],

                resource[:name],
                resource[:pattern],
                JSON.generate(resource[:definition]))
  end

  def destroy_policy(resource)
    rabbitmqctl('clear_policy',
                "-p",
                resource[:vhost],
                resource[:name])
  end

  def policy_exists(resource)
    output = rabbitmqctl('list_policies', '-q', '-p', resource[:vhost])
    output.split(/\n/).each do |line|
      if line =~ /^(\S+)\s+(\S+)\s+(.*)$/ then
        if $2 == resource[:name]
          return true
        end
      end
    end
    return false
  end

  def create
    create_policy(resource)
  end

  def exists?
    policy_exists(resource)
  end

  def destroy
    destroy_policy(resource)
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
        self.destroy_policy(resource[:vhost], resource[:name])
        return
      end
      create_policy(resource)
  end
end

require 'json'

JSON_KEY_SHOVEL_PARAM_LOOKUP = {
  'src-uri' => :src_uris,
  'src-exchange' => :src_exchange,
  'src-exchange-key' => :src_exchange_key,

  'dest-uri' => :dst_uris,
  'dest-exchange' => :dst_exchange,
  'add-forward-headers' => :add_forward_headers,
  'ack-mode' => :ack_mode,
  'delete-after' => :delete_after,
}
SHOVEL_PARAM_JSON_KEY_LOOKUP = JSON_KEY_SHOVEL_PARAM_LOOKUP.invert


Puppet::Type.type(:rabbitmq_shovel).provide(:rabbitmqctl) do

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
      output = rabbitmqctl('list_parameters', '-q', "-p", vhost).split(/\n/)
      output.each do |line|
        if line =~ /^(\S+)\s+(\S+)\s+(.*)$/ then
          param = {}
          param[:type] = $1
          param[:name] = $2
          param[:value] = $3
          param[:vhost] = vhost
        else
          raise  Puppet::Error, "Cannot parse list_parameters line: #{line}"
        end
      end
    end
    Puppet.debug "RabbitMQ parameters: #{parameters.inspect}"
    parameters
  end

  def json_to_puppet_usable(json_obj)
    # Rename the keys in the json object to be puppet usable
    puppet_obj = {}
    json_obj.keys.each do |k|
      key = JSON_KEY_SHOVEL_PARAM_LOOKUP.fetch(k, nil)
      if key != nil then
        value = json_obj[k]
        puppet_obj[key] = value
      end
    end
    return puppet_obj
  end

  def puppet_to_rabbit_usable_json_obj(resource)
    obj = {}
    SHOVEL_PARAM_JSON_KEY_LOOKUP.keys.each do |k|
      json_key = SHOVEL_PARAM_JSON_KEY_LOOKUP.fetch(k, nil)
      if json_key != nil then
        obj[json_key] = resource[k]
      end
    end
    return obj
  end

  def self.param_to_shovel(param)
    shovel = {}
    shovel[:name] = param[:name]
    shovel[:vhost] = param[:vhost]

    # Normalize the json to the format puppet expects
    param_json = JSON.parse[:value]
    mangled_json = json_to_puppet_usable(param_json)

    shovel.merge(mangled_json)
    return shovel
  end


  def self.instances
    self.get_parameters.collect do |param|
      if param[:type] == 'shovel' then
        shovel_hash = self.param_to_shovel(param)
        new(shovel_hash)
      end
    end
  end

  def create_shovel(resource)
    param_obj = self.puppet_to_rabbit_usable_json_obj(resource)
    param_str = JSON.generate(param_obj)
    rabbitmqctl('set_parameter',
                "-p",
                resource[:vhost],
                "shovel",
                resource[:name],
                param_str)
  end

  def destroy_parameter(resource)
    rabbitmqctl('clear_parameter',
                "-p",
                resource[:vhost],
                "shovel",
                resource[:name])
  end

  def parameter_exists(resource)
    output = rabbitmqctl('list_parameters', '-q', '-p', resource[:vhost])
    output.split(/\n/).each do |line|
      if line =~ /^(\S+)\s+(\S+)\s+(\{.*\})$/ then
        json_str = $3
        json_obj = JSON.parse(json_str.strip())
        puppet_obj = puppet_to_rabbit_usable_json_obj(resource)
        if $2 == resource[:name] && puppet_obj == json_obj
          return true
        end
      end
    end
    return false
  end

  def create
    create_shovel(resource)
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

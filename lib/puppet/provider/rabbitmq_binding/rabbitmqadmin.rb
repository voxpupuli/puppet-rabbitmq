require 'json'
require 'puppet'
Puppet::Type.type(:rabbitmq_binding).provide(:rabbitmqadmin) do

  if Puppet::PUPPETVERSION.to_f < 3
    commands :rabbitmqctl   => 'rabbitmqctl'
    commands :rabbitmqadmin => '/usr/local/bin/rabbitmqadmin'
  else
    has_command(:rabbitmqctl, 'rabbitmqctl') do
      environment :HOME => "/tmp"
    end
    has_command(:rabbitmqadmin, '/usr/local/bin/rabbitmqadmin') do
      environment :HOME => "/tmp"
    end
  end
  defaultfor :feature => :posix

  def should_vhost
    if @should_vhost
      @should_vhost
    else
      @should_vhost = resource[:name].split('@').last
    end
  end

  def self.all_vhosts
    vhosts = []
    rabbitmqctl('list_vhosts', '-q').split(/\n/).collect do |vhost|
      vhosts.push(vhost)
    end
    vhosts
  end

  def self.all_bindings(vhost)
    rabbitmqctl('list_bindings', '-q', '-p', vhost, 'source_name', 'destination_name', 'destination_kind', 'routing_key', 'arguments').split(/\n/)
  end

  def self.instances
    resources = []
    all_vhosts.each do |vhost|
      vhost_bindings = {}
      all_bindings(vhost).collect do |line|
        source_name, destination_name, destination_type, routing_key, arguments = line.split(/\t/)
        # Convert output of arguments from the rabbitmqctl command to a json string.
        if !arguments.nil?
          arguments = arguments.gsub(/^\[(.*)\]$/, "").gsub(/\{("(?:.|\\")*?"),/, '{\1:').gsub(/\},\{/, ",")
          if arguments == ""
            arguments = '{}'
          end
        else
          arguments = '{}'
        end

        unless(source_name.empty?)
          name = "%s@%s@%s" % [source_name, destination_name, vhost]
          if not vhost_bindings[name]
            vhost_bindings[name] = []
            vhost_bindings[name] = [source_name, destination_name, destination_type, [routing_key], arguments]
          else
            vhost_bindings[name][3].push(routing_key)
          end
        end

      end

      vhost_bindings.each do |name, values|
        values[3].sort!
        source_name, destination_name, destination_type, routing_key, arguments = values
        binding = {
          :destination_type => destination_type,
          :routing_key      => routing_key,
          :arguments        => JSON.parse(arguments),
          :ensure           => :present,
          :name             => name,
        }
        resources << new(binding) if binding[:name]
      end

    end
    resources
  end

  def self.prefetch(resources)
    packages = instances
    resources.keys.each do |name|
      if provider = packages.find{ |pkg| pkg.name == name }
        resources[name].provider = provider
      end
    end
  end

  def exists?
    @property_hash[:ensure] == :present
  end

  def create
    vhost_opt = should_vhost ? "--vhost=#{should_vhost}" : ''
    name = resource[:name].split('@').first
    destination = resource[:name].split('@')[1]
    arguments = resource[:arguments]
    if arguments.nil?
      arguments = {}
    end
    # Accommodate multiple bindings with different routing keys
    for routing_key in resource[:routing_key]
      rabbitmqadmin('declare',
        'binding',
        vhost_opt,
        "--user=#{resource[:user]}",
        "--password=#{resource[:password]}",
        '-c',
        '/etc/rabbitmq/rabbitmqadmin.conf',
        "source=#{name}",
        "destination=#{destination}",
        "arguments=#{arguments.to_json}",
        "routing_key=#{routing_key}",
        "destination_type=#{resource[:destination_type]}"
      )
    end
    @property_hash[:ensure] = :present
  end

  def destroy
    vhost_opt = should_vhost ? "--vhost=#{should_vhost}" : ''
    name = resource[:name].split('@').first
    destination = resource[:name].split('@')[1]
    # This is not really ideal; since you still can't have duplicate
    # resources, you could ensure that the binding with one or more
    # routing keys is absent, but you couldn't ensure that one routing
    # key is present but others absent for the same binding name.
    for routing_key in resource[:routing_key]
      rabbitmqadmin('delete', 'binding', vhost_opt, "--user=#{resource[:user]}", "--password=#{resource[:password]}", '-c', '/etc/rabbitmq/rabbitmqadmin.conf', "source=#{name}", "destination_type=#{resource[:destination_type]}", "destination=#{destination}", "properties_key=#{routing_key}")
    end
    @property_hash[:ensure] = :absent
  end

end

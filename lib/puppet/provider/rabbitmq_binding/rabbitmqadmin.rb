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
      @should_vhost = resource[:vhost]
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
          binding = {
            :source           => source_name,
            :dest             => destination_name,
            :vhost            => vhost,
            :destination_type => destination_type,
            :routing_key      => routing_key,
            :arguments        => JSON.parse(arguments),
            :ensure           => :present,
            :name             => "%s@%s@%s@%s" % [source_name, destination_name, vhost, routing_key],
          }
          resources << new(binding) if binding[:name]
        end
      end
    end
    resources
  end

  def self.prefetch(resources)
    bindings = instances
    resources.keys.each do |name|
      if provider = bindings.find{ |route| route.source == source && route.dest == dest && route.vhost == vhost && route.routing_key == routing_key }
        resources[name].provider = provider
      end
    end
  end

  def exists?
    @property_hash[:ensure] == :present
  end

  def create
    vhost_opt = should_vhost ? "--vhost=#{should_vhost}" : ''
    arguments = resource[:arguments]
    if arguments.nil?
      arguments = {}
    end
    rabbitmqadmin('declare',
      'binding',
      vhost_opt,
      "--user=#{resource[:user]}",
      "--password=#{resource[:password]}",
      '-c',
      '/etc/rabbitmq/rabbitmqadmin.conf',
      "source=#{resource[:source]}",
      "destination=#{resource[:dest]}",
      "arguments=#{arguments.to_json}",
      "routing_key=#{resource[:routing_key]}",
      "destination_type=#{resource[:destination_type]}"
    )
    @property_hash[:ensure] = :present
  end

  def destroy
    vhost_opt = should_vhost ? "--vhost=#{should_vhost}" : ''
    rabbitmqadmin('delete', 'binding', vhost_opt, "--user=#{resource[:user]}", "--password=#{resource[:password]}", '-c', '/etc/rabbitmq/rabbitmqadmin.conf', "source=#{resource[:source]}", "destination_type=#{resource[:destination_type]}", "destination=#{resource[:dest]}", "properties_key=#{resource[:routing_key]}")
    @property_hash[:ensure] = :absent
  end

end

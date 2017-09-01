require 'puppet'

require "rabbitmq/http/client"

$endpoint = "http://localhost:15672"
$client = RabbitMQ::HTTP::Client.new($endpoint, :username => "guest", :password => "guest")

Puppet::Type.type(:rabbitmq_exchange).provide(:rabbitmqhttp, :parent => Puppet::Type.type(:rabbitmq_exchange).provider(:rabbitmqctl)) do


  defaultfor :feature => :posix

  def should_vhost
    if @should_vhost
      @should_vhost
    else
      @should_vhost = resource[:name].split('@')[1]
    end
  end

  def self.all_vhosts
    vhosts = []
    vhost_list = $client.list_vhosts
    vhost_list.each do |vhost|
      vhosts.push(vhost[:name])
    end
    vhosts
  end

  def self.all_exchanges(vhost)
    exchanges = []
    exchange_list = $client.list_exchanges(vhost)
    exchange_list.each do |exchange|
      next if exchange.name.eql? ''
      json_args = exchange.arguments.to_json
      tmp_exchange = "#{exchange.name} #{exchange.type} #{exchange.internal} #{exchange.durable} #{exchange.auto_delete} #{json_args}"
      exchanges.push(tmp_exchange)
    end
    exchanges
  end

  def self.instances
    resources = []
    all_vhosts.each do |vhost|
        all_exchanges(vhost).each do |line|
          name, type, internal, durable, auto_delete, arguments = line.split()
            if type.nil?
                # if name is empty, it will wrongly get the type's value.
                # This way type will get the correct value
                type = name
                name = ''
            end
            # Convert output of arguments from the rabbitmqctl command to a json string.
            if !arguments.nil?
              arguments = arguments.gsub(/^\[(.*)\]$/, "").gsub(/\{("(?:.|\\")*?"),/, '{\1:').gsub(/\},\{/, ",")
              if arguments == ""
                arguments = '{}'
              end
            else
              arguments = '{}'
            end
            exchange = {
              :type   => type,
              :ensure => :present,
              :internal => internal,
              :durable => durable,
              :auto_delete => auto_delete,
              :name   => "%s@%s" % [name, vhost],
              :arguments => JSON.parse(arguments),
            }
            resources << new(exchange) if exchange[:type]
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
    exchange_list = $client.list_exchanges(resource[:name].split('@')[1])
    exchange_list.each do |line|
      if line.name.eql? resource[:name].split('@')[0]
        return true
      end
    end
    false
  end

  def create
    name = resource[:name].split('@')[0]
    arguments = resource[:arguments]
    if arguments.nil?
      arguments = {}
    end

    $client.declare_exchange(should_vhost, name, :durable => resource[:durable], :type => resource[:type])
    @property_hash[:ensure] = :present
  end

  def destroy
    $client.delete_exchange(should_vhost, name, if_unused = false)
    @property_hash[:ensure] = :absent
  end

end

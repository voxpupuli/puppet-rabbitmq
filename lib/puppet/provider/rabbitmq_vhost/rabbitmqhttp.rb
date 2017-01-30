require "rabbitmq/http/client"

$endpoint = "http://localhost:15672"
$client = RabbitMQ::HTTP::Client.new($endpoint, :username => "guest", :password => "guest")

Puppet::Type.type(:rabbitmq_vhost).provide(:rabbitmqhttp, :parent => Puppet::Type.type(:rabbitmq_vhost).provider(:rabbitmqctl)) do

  def self.instances
  end

  def create
    $client.create_vhost(resource[:name])
  end

  def destroy
    $client.delete_vhost(resource[:name])
  end

  def exists?
    v_list = $client.list_vhosts

    out = false
    v_list.each {|line|
      if (line[:name].match(/^#{Regexp.escape(resource[:name])}$/))
          out = true
      end
      }
    return out
  end
end


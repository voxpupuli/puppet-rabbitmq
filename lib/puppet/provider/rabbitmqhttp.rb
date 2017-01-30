require "rabbitmq/http/client"

$endpoint = "http://localhost:15672"
$client = RabbitMQ::HTTP::Client.new($endpoint, :username => "guest", :password => "guest")

class Puppet::Provider::Rabbitmqhttp < Puppet::Provider
  initvars

  def self.rabbitmq_version
    $client.overview[:rabbitmq_version]
  end
end

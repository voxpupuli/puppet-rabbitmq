class Puppet::Provider::Rabbitmqctl < Puppet::Provider
  initvars
  commands :rabbitmqctl => 'rabbitmqctl'

  def self.rabbitmq_version
    output = rabbitmqctl('-q', 'status')
    version = output.match(/\{rabbit,"RabbitMQ","([\d\.]+)"\}/)
    version[1] if version
  end
end

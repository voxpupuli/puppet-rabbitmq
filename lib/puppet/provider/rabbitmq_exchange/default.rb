Puppet::Type.type(:rabbitmq_exchange).provide(:default) do

  def self.instances
    []
  end

  def create
    default_fail
  end

  def destroy
    default_fail
  end

  def exists?
    default_fail
  end

  def default_fail
    fail('This is just the default provider for rabbitmq_exchange, all it does is fail')
  end
end

require File.join File.dirname(__FILE__), './rabbitmq_common.rb'

# Abstract
class Puppet::Provider::Rabbitmq_wait < Puppet::Provider

  private

  include RabbitmqCommon
  extend RabbitmqCommon
end

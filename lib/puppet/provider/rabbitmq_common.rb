require 'rubygems'
require 'puppet'
require 'puppet/util'
require 'puppet/util/execution'

module RabbitmqCommon
  # Wait 'count*step' seconds while RabbitMQ is ready (able to list its users&channels)
  # Make 'count' retries with 'step' delay between retries.
  # Limit each query time by 'timeout'
  def wait_for_rabbitmq(count=30, step=6, timeout=10)
    (0...count).each do |n|
      begin
        # Note, that then RabbitMQ cluster is broken or not ready, it might not show its
        # channels some times and hangs for ever, so we have to specify a timeout as well
        Timeout::timeout(timeout) do
          if Puppet::Util::Execution.respond_to? :execute
            Puppet::Util::Execution.execute 'rabbitmqctl list_users'
            Puppet::Util::Execution.execute 'rabbitmqctl list_channels'
          else
            Puppet::Util.execute 'rabbitmqctl list_users'
            Puppet::Util.execute 'rabbitmqctl list_channels'
          end
        end
      rescue Puppet::ExecutionFailure, Timeout
        Puppet.debug "RabbitMQ is not ready, retrying"
        sleep step
      else
        Puppet.debug "RabbitMQ is online after #{n * step} seconds"
        return true
      end
    end
    raise Puppet::Error, "RabbitMQ is not ready after #{count * step} seconds expired!"
  end
end

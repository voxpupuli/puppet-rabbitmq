class Puppet::Provider::Rabbitmq_common < Puppet::Provider
  initvars
  commands :rabbitmqctl => 'rabbitmqctl'

  # Wait 'count*step' seconds while RabbitMQ is ready (able to list its users&channels)
  # Make 'count' retries with 'step' delay between retries.
  # Limit each query time by 'timeout'
  def self.wait_for_online(count=30, step=6, timeout=10)
    count.times do |n|
      begin
        # Note, that then RabbitMQ cluster is broken or not ready, it might not show its
        # channels some times and hangs for ever, so we have to specify a timeout as well
        Timeout::timeout(timeout) do
          rabbitmqctl 'status'
        end
      rescue Puppet::ExecutionFailure, Timeout
        Puppet.debug 'RabbitMQ is not ready, retrying'
        sleep step
      else
        Puppet.debug "RabbitMQ is online after #{n * step} seconds"
        return true
      end
    end
    raise Puppet::Error, "RabbitMQ is not ready after #{count * step} seconds expired!"
  end

  # retry the given code block until command suceeeds
  # for example:
  # users = self.class.run_with_retries { rabbitmqctl 'list_users' }
  def self.run_with_retries(count=30, step=6, timeout=10)
    count.times do |n|
      begin
        output = Timeout::timeout(timeout) do
          yield
        end
      rescue Puppet::ExecutionFailure, Timeout
        Puppet.debug 'Command failed, retrying'
        sleep step
      else
        Puppet.debug 'Command succeeded'
        return output
      end
    end
    raise Puppet::Error, "Command is still failing after #{count * step} seconds expired!"
  end

end

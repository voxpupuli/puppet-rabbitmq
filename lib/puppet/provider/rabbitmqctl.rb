class Puppet::Provider::Rabbitmqctl < Puppet::Provider
  initvars
  commands rabbitmqctl: 'rabbitmqctl'

  def self.rabbitmq_version
    output = rabbitmqctl('-q', 'status')
    version = output.match(%r{\{rabbit,"RabbitMQ","([\d\.]+)"\}})
    return unless version
    @rabbit_version = version[1]
    version[1]
  end

  def self.exec_args
    if @rabbit_version
      if Gem::Version.new(@rabbit_version) >= Gem::Version.new('3.7.9')
        ['--no-table-headers', '-q']
      else
        '-q'
      end
    else
      # rabbit_version is unknown, run rabbitmq_version function
      # to update the local instance variable rabbit_version
      rabbitmq_version
      exec_args
    end
  end

  # Retry the given code block 'count' retries or until the
  # command suceeeds. Use 'step' delay between retries.
  # Limit each query time by 'timeout'.
  # For example:
  #   users = self.class.run_with_retries { rabbitmqctl 'list_users' }
  def self.run_with_retries(count = 30, step = 6, timeout = 10)
    count.times do |_n|
      begin
        output = Timeout.timeout(timeout) do
          yield
        end
      rescue Puppet::ExecutionFailure, Timeout::Error
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

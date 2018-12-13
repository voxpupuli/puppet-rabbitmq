class Puppet::Provider::Rabbitmqctl < Puppet::Provider
  initvars
  commands rabbitmqctl: 'rabbitmqctl'

  def self.rabbitmq_version
    output = rabbitmqctl('-q', 'status')
    version = output.match(%r{\{rabbit,"RabbitMQ","([\d\.]+)"\}})
    version[1] if version
  end

  # rabbitmqctl version 3.7.9 introduced --no-table-headers flag
  # which began causing problems for parsing. This resolves the issue
  # by automatically adding the required flag in the event the RabbitMQ
  # version is at or above 3.7.9
  if Puppet::Util::Package.versioncmp(rabbitmq_version, '3.7.9') >= 0
    commands rabbitmqctl: 'rabbitmqctl --no-table-headers'
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

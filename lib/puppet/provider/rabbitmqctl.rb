class Puppet::Provider::Rabbitmqctl < Puppet::Provider
  initvars
  commands rabbitmqctl: 'rabbitmqctl'

  def self.rabbitmq_version
    output = rabbitmqctl('-q', 'status')
    version = output.match(%r{\{rabbit,"RabbitMQ","([\d\.]+)"\}})
    if version
      if Puppet::Util::Package.versioncmp(version[1], '3.7.9') >= 0
        @format_table_headers = '--no-table-headers'
      else
        @format_table_headers = nil
      end
      version[1]
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

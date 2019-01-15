class Puppet::Provider::RabbitmqCli < Puppet::Provider
  initvars

  def self.rabbitmq_command(name, binary)
    path = Puppet::Util.which(binary) || "/usr/lib/rabbitmq/bin/#{binary}"
    home_tmp_command name, path
  end

  def self.home_tmp_command(name, path)
    has_command name, path do
      environment HOME: '/tmp'
    end
  end

  rabbitmq_command :rabbitmqctl, 'rabbitmqctl'
  rabbitmq_command :rabbitmqplugins, 'rabbitmq-plugins'

  home_tmp_command :rabbitmqadmin, '/usr/local/bin/rabbitmqadmin'

  def self.rabbitmq_version
    return @rabbitmq_version if defined? @rabbitmq_version

    output = rabbitmqctl('-q', 'status')
    version = output.match(%r{\{rabbit,"RabbitMQ","([\d\.]+)"\}})
    @rabbitmq_version = version[1] if version
  end

  def self.rabbitmqctl_list(resource, *opts)
    list_opts =
      if Puppet::Util::Package.versioncmp(rabbitmq_version, '3.7.9') >= 0
        ['-q', '--no-table-headers']
      else
        ['-q']
      end
    rabbitmqctl("list_#{resource}", *list_opts, *opts)
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

  def self.define_instance_method(name)
    return if method_defined?(name)
    define_method(name) do |*args, &block|
      self.class.send(name, *args, &block)
    end
  end
  private_class_method :define_instance_method

  define_instance_method :rabbitmqctl_list
  define_instance_method :run_with_retries
end

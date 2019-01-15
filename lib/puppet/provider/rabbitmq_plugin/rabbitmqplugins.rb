require File.expand_path(File.join(File.dirname(__FILE__), '..', 'rabbitmq_cli'))
Puppet::Type.type(:rabbitmq_plugin).provide(:rabbitmqplugins, parent: Puppet::Provider::RabbitmqCli) do
  confine feature: :posix

  def self.instances
    plugin_list = run_with_retries do
      rabbitmqplugins('list', '-E', '-m')
    end

    plugin_list.split(%r{\n}).map do |line|
      raise Puppet::Error, "Cannot parse invalid plugins line: #{line}" unless line =~ %r{^(\S+)$}
      new(name: Regexp.last_match(1))
    end
  end

  def create
    if resource[:umask].nil?
      rabbitmqplugins('enable', resource[:name])
    else
      Puppet::Util.withumask(resource[:umask]) { rabbitmqplugins('enable', resource[:name]) }
    end
  end

  def destroy
    rabbitmqplugins('disable', resource[:name])
  end

  def exists?
    run_with_retries { rabbitmqplugins('list', '-E', '-m') }.split(%r{\n}).include? resource[:name]
  end
end

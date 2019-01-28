require 'puppet/util/package'

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
    cmd = ['enable', resource[:name]]
    # rabbitmq>=3.4.0 - check if node running, if not, ignore this option
    cmd << "--#{resource[:mode]}" if self.class.rabbitmq_running && Puppet::Util::Package.versioncmp(self.class.rabbitmq_version, '3.4') >= 0 && resource[:mode] != :best

    if resource[:umask].nil?
      rabbitmqplugins(*cmd)
    else
      Puppet::Util.withumask(resource[:umask]) { rabbitmqplugins(*cmd) }
    end
  end

  def destroy
    rabbitmqplugins('disable', resource[:name])
  end

  def exists?
    run_with_retries { rabbitmqplugins('list', '-E', '-m') }.split(%r{\n}).include? resource[:name]
  end
end

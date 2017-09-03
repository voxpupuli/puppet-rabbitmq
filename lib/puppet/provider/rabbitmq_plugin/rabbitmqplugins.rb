require File.expand_path(File.join(File.dirname(__FILE__), '..', 'rabbitmqctl'))
Puppet::Type.type(:rabbitmq_plugin).provide(:rabbitmqplugins, parent: Puppet::Provider::Rabbitmqctl) do
  case Facter.value(:osfamily)
  when 'RedHat'
    has_command(:rabbitmqplugins, '/usr/lib/rabbitmq/bin/rabbitmq-plugins') { environment HOME: '/tmp' }
  else
    has_command(:rabbitmqplugins, 'rabbitmq-plugins') { environment HOME: '/tmp' }
  end

  defaultfor feature: :posix

  def self.instances
    plugin_list = run_with_retries do
      rabbitmqplugins('list', '-E', '-m')
    end

    plugin_list.split(%r{\n}).map do |line|
      if line =~ %r{^(\S+)$}
        new(name: Regexp.last_match(1))
      else
        raise Puppet::Error, "Cannot parse invalid plugins line: #{line}"
      end
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
    self.class.run_with_retries { rabbitmqplugins('list', '-E', '-m') }.split(%r{\n}).include? resource[:name]
  end
end

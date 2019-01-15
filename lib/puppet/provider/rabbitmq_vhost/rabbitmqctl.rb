require File.expand_path(File.join(File.dirname(__FILE__), '..', 'rabbitmq_cli'))
Puppet::Type.type(:rabbitmq_vhost).provide(:rabbitmqctl, parent: Puppet::Provider::RabbitmqCli) do
  confine feature: :posix

  def self.instances
    vhost_list = run_with_retries do
      rabbitmqctl_list('vhosts')
    end

    vhost_list.split(%r{\n}).map do |line|
      raise Puppet::Error, "Cannot parse invalid vhost line: #{line}" unless line =~ %r{^(\S+)$}
      new(name: Regexp.last_match(1))
    end
  end

  def create
    rabbitmqctl('add_vhost', resource[:name])
  end

  def destroy
    rabbitmqctl('delete_vhost', resource[:name])
  end

  def exists?
    self.class.run_with_retries { self.class.rabbitmqctl_list('vhosts') }.split(%r{\n}).include? resource[:name]
  end
end

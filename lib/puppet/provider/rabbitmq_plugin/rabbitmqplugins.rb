Puppet::Type.type(:rabbitmq_plugin).provide(:rabbitmqplugins) do

  defaultfor :feature => :posix

  def initialize(*args)
	super
    @@rabbitmqplugins = Puppet::Provider::Command.new('rabbitmqplugins', 'rabbitmq-plugins', Puppet::Util, Puppet::Util::Execution, { :failonfail => true, :combine => true, :custom_environment => { 'HOME' => '/root' } })
  end

  def self.instances
    @@rabbitmqplugins.execute('list', '-E').split(/\n/).map do |line|
      if line.split(/\s+/)[1] =~ /^(\S+)$/
        new(:name => $1)
      else
        raise Puppet::Error, "Cannot parse invalid plugins line: #{line}"
      end
    end
  end

  def create
    @@rabbitmqplugins.execute('enable', resource[:name])
  end

  def destroy
    @@rabbitmqplugins.execute('disable', resource[:name])
  end

  def exists?
    out = @@rabbitmqplugins.execute('list', '-E').split(/\n/).detect do |line|
      line.split(/\s+/)[1].match(/^#{resource[:name]}$/)
    end
  end

end

Puppet::Type.type(:rabbitmq_plugin).provide(:rabbitmq-plugins) do

  commands :rabbitmq-plugins => 'rabbitmq-plugins'
  defaultfor :feature => :posix

  def self.instances
    rabbitmq-plugins('list -e').split(/\n/).map do |line|
      if line.split(/\s+/)[1] =~ /^(\S+)$/
        new(:name => $1)
      else
        raise Puppet::Error, "Cannot parse invalid plugins line: #{line}"
      end
    end
  end

  def create
    rabbitmq-plugins('enable', resource[:name])
  end

  def destroy
    rabbitmq-plugins('disable', resource[:name])
  end

  def exists?
    out = rabbitmq-plugins('list -e').split(/\n/).detect do |line|
      line.split(/\s+/)[1].match(/^#{resource[:name]}$/)
    end
  end

end

require 'puppet'
Puppet::Type.type(:rabbitmq_policy).provide(:rabbitmqctl) do

  commands :rabbitmqctl => 'rabbitmqctl'
  defaultfor :feature => :posix

  def should_vhost
    if @should_vhost
      @should_vhost
    else
      @should_vhost = resource[:vhost]
    end
  end

  def self.instances
    rabbitmqctl('-q', 'list_policies', '-p', should_vhost).split(/\n/).detect do |line|
      if line =~ /^(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+.*$/
        new(:name => $2, :vhost => $1, :match => $3, :policy => $4)
      else
        raise Puppet::Error, "Cannot parse invalid user line: #{line}"
      end
    end
  end

  def create
    rabbitmqctl('-q', 'set_policy', '-p', should_vhost, resource[:name], resource[:match], resource[:policy])
  end

  def destroy
    rabbitmqctl('-q', 'clear_policy', '-p', should_vhost, resource[:name])
  end

  def exists?
    out = rabbitmqctl('-q', 'list_policies', '-p', should_vhost).split(/\n/).detect do |line|
      line.match(/^\S+\s+#{resource[:name]}\s+\S+.*$/)
    end
  end

end

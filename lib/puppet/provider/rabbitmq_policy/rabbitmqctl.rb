require 'puppet'
Puppet::Type.type(:rabbitmq_policy).provide(:rabbitmqctl) do

  if Puppet::PUPPETVERSION.to_f < 3
    commands :rabbitmqctl => 'rabbitmqctl'
  else
     has_command(:rabbitmqctl, 'rabbitmqctl') do
       environment :HOME => "/tmp"
     end
  end

  defaultfor :feature => :posix

  def should_vhost
    if @should_vhost
      @should_vhost
    else
      @should_vhost = resource[:vhost]
    end
  end

  def self.instances
    rabbitmqctl('list_policies', '-p', should_vhost).split(/\n/)[1..-2].detect do |line|
      if line =~ /^(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+.*$/
        new(:name => $2, :vhost => $1, :match => $3, :policy => $4)
      else
        raise Puppet::Error, "Cannot parse invalid user line: #{line}"
      end
    end
  end

  def create
    rabbitmqctl('set_policy', '-p', should_vhost, resource[:name], resource[:match], resource[:policy])
  end

  def destroy
    rabbitmqctl('clear_policy', '-p', should_vhost, resource[:name])
  end

  def exists?
    out = rabbitmqctl('list_policies', '-p', should_vhost).split(/\n/)[1..-2].detect do |line|
      line.match(/^\S+\s+#{resource[:name]}\s+\S+.*$/)
    end
  end

end

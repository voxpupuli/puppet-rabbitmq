Puppet::Type.type(:rabbitmq_vhost).provide(:rabbitmqctl) do

  if Puppet::PUPPETVERSION.to_f < 3
    commands :rabbitmqctl => 'rabbitmqctl'
  else
     has_command(:rabbitmqctl, 'rabbitmqctl') do
       environment :HOME => "/tmp"
     end
  end

  def self.instances
  # RabbitMQ 3.4.0 and up no longer include the "...done." at the end
  vhosts_split = rabbitmqctl('list_vhosts').split(/\n/)
  vhosts = vhosts_split[-1] == "...done." ? vhosts_split[1..-2] : vhosts_split[1..-1]

  vhosts.map do |line|
      if line =~ /^(\S+)$/
        new(:name => $1)
      else
        raise Puppet::Error, "Cannot parse invalid user line: #{line}"
      end
    end
  end

  def create
    rabbitmqctl('add_vhost', resource[:name])
  end

  def destroy
    rabbitmqctl('delete_vhost', resource[:name])
  end

  def exists?
    vhosts_split = rabbitmqctl('list_vhosts').split(/\n/)
    vhosts = vhosts_split[-1] == "...done." ? vhosts_split[1..-2] : vhosts_split[1..-1]

    vhosts.detect do |line|
      line.match(/^#{Regexp.escape(resource[:name])}$/)
    end
  end

end

require 'puppet'
Puppet::Type.type(:rabbitmq_exchange).provide(:rabbitmqadmin) do

  if Puppet::PUPPETVERSION.to_f < 3
    commands :rabbitmqadmin => 'rabbitmqadmin'
  else
    has_command(:rabbitmqadmin, 'rabbitmqadmin') do
      environment :HOME => "/tmp"
      environment :PATH => "/usr/local/bin:/usr/bin"
    end
  end
  defaultfor :feature => :posix

  def should_vhost
    if @should_vhost
      @should_vhost
    else
      @should_vhost = resource[:name].split('@')[1]
    end
  end

  def self.instances
    resources = []
    rabbitmqadmin('list', 'exchanges').split(/\n/)[3..-2].collect do |line|
      if line =~ /^\|\s+(\S+)\s+\|\s+(\S+)?\s+\|\s+(\S+)\s+\|\s+(\S+)\s+\|\s+(\S+)\s+\|\s+(\S+)\s+\|$/
        entry = {
          :ensure => :present,
          :name   => "%s@%s" % [$2, $1],
          :type   => $3
        }
        resources << new(entry) if entry[:type]
      else
        raise Puppet::Error, "Cannot parse invalid exchange line: #{line}"
      end
    end
    resources
  end


  def self.prefetch(resources)
    packages = instances
    resources.keys.each do |name|
      if provider = packages.find{ |pkg| pkg.name == name }
        resources[name].provider = provider
      end
    end
  end

  def exists?
    @property_hash[:ensure] == :present
  end

  def create
    vhost_opt = should_vhost ? "--vhost=#{should_vhost}" : ''
    name = resource[:name].split('@')[0]
    if resource[:user] and resource[:password]
	    rabbitmqadmin('declare', 'exchange',
                    "--username=#{resource[:user]}", "--password=#{resource[:password]}",
                    vhost_opt, "name=#{name}", "type=#{resource[:type]}")
    else
	    rabbitmqadmin('declare', 'exchange', vhost_opt, "name=#{name}", "type=#{resource[:type]}")
    end
    @property_hash[:ensure] = :present
  end

  def destroy
    vhost_opt = should_vhost ? "--vhost=#{should_vhost}" : ''
    name = resource[:name].split('@')[0]
    if resource[:user] and resource[:password]
      rabbitmqadmin('delete', 'exchange',
                    "--username=#{resource[:user]}", "--password=#{resource[:password]}",
                    vhost_opt, "name=#{name}")
    else
	    rabbitmqadmin('delete', 'exchange', vhost_opt, "name=#{name}")
    end
    @property_hash[:ensure] = :absent
  end

end

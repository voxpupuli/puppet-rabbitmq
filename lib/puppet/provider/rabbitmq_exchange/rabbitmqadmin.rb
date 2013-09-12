require 'puppet'
Puppet::Type.type(:rabbitmq_exchange).provide(:rabbitmqadmin) do

  commands :rabbitmqadmin => '/usr/local/bin/rabbitmqadmin'
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
    rabbitmqadmin('declare', 'exchange', vhost_opt, "--user=#{resource[:user]}", "--password=#{resource[:password]}", "name=#{name}", "type=#{resource[:type]}")
    @property_hash[:ensure] = :present
  end

  def destroy
    vhost_opt = should_vhost ? "--vhost=#{should_vhost}" : ''
    name = resource[:name].split('@')[0]
    rabbitmqadmin('delete', 'exchange', vhost_opt, "--user=#{resource[:user]}", "--password=#{resource[:password]}", "name=#{name}")
    @property_hash[:ensure] = :absent
  end

end

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

  def self.instances (resource_hash)
    resources = []
    first     = resource_hash.values.first
    rabbitmq  = first ? first.catalog.resource('Class', 'rabbitmq') : {}
    user_opt  = rabbitmq[:rabbitmqadmin_user] ? "-u#{rabbitmq[:rabbitmqadmin_user]}" : ''
    pass_opt  = rabbitmq[:rabbitmqadmin_pass] ? "-p#{rabbitmq[:rabbitmqadmin_pass]}" : ''
    result    = rabbitmqadmin('list', 'exchanges', user_opt, pass_opt).split(/\n/)

    return resources if result.length < 2

    result[3..-2].collect do |line|
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
    packages = instances(resources)
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

    rabbitmq  = resource.catalog.resource('Class', 'rabbitmq')
    user_opt  = rabbitmq[:rabbitmqadmin_user] ? "-u#{rabbitmq[:rabbitmqadmin_user]}" : (resource[:user] ? "--user=#{resource[:user]}" : '')
    pass_opt  = rabbitmq[:rabbitmqadmin_pass] ? "-p#{rabbitmq[:rabbitmqadmin_pass]}" : (resource[:password] ? "--password=#{resource[:password]}" : '')
    vhost_opt = should_vhost ? "--vhost=#{should_vhost}" : ''
    name      = resource[:name].split('@')[0]

    rabbitmqadmin('declare', 'exchange', vhost_opt, user_opt, pass_opt, "name=#{name}", "type=#{resource[:type]}")

    @property_hash[:ensure] = :present
  end

  def destroy
    rabbitmq  = resource.catalog.resource('Class', 'rabbitmq')
    user_opt  = rabbitmq[:rabbitmqadmin_user] ? "-u#{rabbitmq[:rabbitmqadmin_user]}" : (resource[:user] ? "--user=#{resource[:user]}" : '')
    pass_opt  = rabbitmq[:rabbitmqadmin_pass] ? "-p#{rabbitmq[:rabbitmqadmin_pass]}" : (resource[:password] ? "--password=#{resource[:password]}" : '')
    vhost_opt = should_vhost ? "--vhost=#{should_vhost}" : ''
    name      = resource[:name].split('@')[0]

    rabbitmqadmin('delete', 'exchange', vhost_opt, user_opt, pass_opt, "name=#{name}")

    @property_hash[:ensure] = :absent
  end

end

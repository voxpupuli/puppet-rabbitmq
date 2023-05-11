# frozen_string_literal: true

require 'puppet'
require File.expand_path(File.join(File.dirname(__FILE__), '..', 'rabbitmq_cli'))
Puppet::Type.type(:rabbitmq_exchange).provide(:rabbitmqadmin, parent: Puppet::Provider::RabbitmqCli) do
  confine feature: :posix

  def should_vhost
    @should_vhost || @should_vhost = resource[:name].split('@')[1]
  end

  def self.all_vhosts
    run_with_retries { rabbitmqctl_list('vhosts') }.split(%r{\n})
  end

  def self.all_exchanges(vhost)
    exchange_list = run_with_retries do
      rabbitmqctl_list('exchanges', '-p', vhost, 'name', 'type', 'internal', 'durable', 'auto_delete', 'arguments')
    end
    exchange_list.split(%r{\n}).grep_v(%r{^federation:})
  end

  def self.instances
    resources = []
    all_vhosts.each do |vhost|
      all_exchanges(vhost).each do |line|
        name, type, internal, durable, auto_delete, arguments = line.split
        if type.nil?
          # if name is empty, it will wrongly get the type's value.
          # This way type will get the correct value
          type = name
          name = ''
        end
        # Convert output of arguments from the rabbitmqctl command to a json string.
        if arguments.nil?
          arguments = '{}'
        else
          arguments = arguments.gsub(%r{^\[(.*)\]$}, '').gsub(%r{\{("(?:.|\\")*?"),}, '{\1:').gsub(%r{\},\{}, ',')
          arguments = '{}' if arguments == ''
        end
        exchange = {
          type: type,
          ensure: :present,
          internal: internal,
          durable: durable,
          auto_delete: auto_delete,
          name: format('%s@%s', name, vhost),
          arguments: JSON.parse(arguments)
        }
        resources << new(exchange) if exchange[:type]
      end
    end
    resources
  end

  def self.prefetch(resources)
    packages = instances
    resources.each_key do |name|
      if (provider = packages.find { |pkg| pkg.name == name })
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
    arguments = resource[:arguments]
    arguments = {} if arguments.nil?
    cmd = ['declare', 'exchange', vhost_opt, "--user=#{resource[:user]}", "--password=#{resource[:password]}", "name=#{name}", "type=#{resource[:type]}"]
    cmd << "internal=#{resource[:internal]}"
    cmd << "durable=#{resource[:durable]}"
    cmd << "auto_delete=#{resource[:auto_delete]}"
    cmd += ["arguments=#{arguments.to_json}", '-c', '/etc/rabbitmq/rabbitmqadmin.conf']
    rabbitmqadmin(*cmd)
    @property_hash[:ensure] = :present
  end

  def destroy
    vhost_opt = should_vhost ? "--vhost=#{should_vhost}" : ''
    name = resource[:name].split('@')[0]
    rabbitmqadmin('delete', 'exchange', vhost_opt, "--user=#{resource[:user]}", "--password=#{resource[:password]}", "name=#{name}", '-c', '/etc/rabbitmq/rabbitmqadmin.conf')
    @property_hash[:ensure] = :absent
  end
end

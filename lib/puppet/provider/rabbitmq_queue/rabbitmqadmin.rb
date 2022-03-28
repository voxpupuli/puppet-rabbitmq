# frozen_string_literal: true

require 'json'
require 'puppet'

require File.expand_path(File.join(File.dirname(__FILE__), '..', 'rabbitmq_cli'))
Puppet::Type.type(:rabbitmq_queue).provide(:rabbitmqadmin, parent: Puppet::Provider::RabbitmqCli) do
  confine feature: :posix

  def should_vhost
    @should_vhost || @should_vhost = resource[:name].rpartition('@').last
  end

  def self.all_vhosts
    rabbitmqctl_list('vhosts').split(%r{\n})
  end

  def self.all_queues(vhost)
    rabbitmqctl_list('queues', '-p', vhost, 'name', 'durable', 'auto_delete', 'arguments').split(%r{\n})
  end

  def self.instances
    resources = []
    all_vhosts.each do |vhost|
      all_queues(vhost).map do |line|
        next if line =~ %r{^federation:}

        name, durable, auto_delete, arguments = line.split("\t")
        # Convert output of arguments from the rabbitmqctl command to a json string.
        if arguments.nil?
          arguments = '{}'
        else
          arguments = arguments.gsub(%r{^\[(.*)\]$}, '').gsub(%r{\{("(?:.|\\")*?"),}, '{\1:').gsub(%r{\},\{}, ',')
          arguments = '{}' if arguments == ''
        end
        queue = {
          durable: durable,
          auto_delete: auto_delete,
          arguments: JSON.parse(arguments),
          ensure: :present,
          name: format('%s@%s', name, vhost)
        }
        resources << new(queue) if queue[:name]
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
    name = resource[:name].rpartition('@').first
    arguments = resource[:arguments]
    arguments = {} if arguments.nil?
    rabbitmqadmin('declare',
                  'queue',
                  vhost_opt,
                  "--user=#{resource[:user]}",
                  "--password=#{resource[:password]}",
                  '-c',
                  '/etc/rabbitmq/rabbitmqadmin.conf',
                  "name=#{name}",
                  "durable=#{resource[:durable]}",
                  "auto_delete=#{resource[:auto_delete]}",
                  "arguments=#{arguments.to_json}")
    @property_hash[:ensure] = :present
  end

  def destroy
    vhost_opt = should_vhost ? "--vhost=#{should_vhost}" : ''
    name = resource[:name].rpartition('@').first
    rabbitmqadmin('delete', 'queue', vhost_opt, "--user=#{resource[:user]}", "--password=#{resource[:password]}", '-c', '/etc/rabbitmq/rabbitmqadmin.conf', "name=#{name}")
    @property_hash[:ensure] = :absent
  end
end

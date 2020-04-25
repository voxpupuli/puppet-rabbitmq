require 'json'
require 'puppet/util/package'

require File.expand_path(File.join(File.dirname(__FILE__), '..', 'rabbitmq_cli'))
Puppet::Type.type(:rabbitmq_parameter).provide(:rabbitmqctl, parent: Puppet::Provider::RabbitmqCli) do
  confine feature: :posix

  mk_resource_methods

  def initialize(value = {})
    super(value)
    @property_flush = {}
  end

  def self.all_vhosts
    rabbitmqctl_list('vhosts').split(%r{\n})
  end

  def self.all_parameters(vhost)
    rabbitmqctl_list('parameters', '-p', vhost).split(%r{\n})
  end

  def self.instances
    resources = []
    all_vhosts.each do |vhost|
      all_parameters(vhost).map do |line|
        raise Puppet::Error, "cannot parse line from list_parameter:#{line}" unless line =~ %r{^(\S+)\s+(\S+)\s+(\S+)$}
        parameter = {
          ensure: :present,
          component_name: Regexp.last_match(1),
          name: format('%s@%s', Regexp.last_match(2), vhost),
          value: JSON.parse(Regexp.last_match(3))
        }
        resources << new(parameter)
      end
    end
    resources
  end

  def self.prefetch(resources)
    packages = instances
    resources.keys.each do |name|
      Puppet.info "Calling prefetch: #{name}"
      if (provider = packages.find { |pkg| pkg.name == name })
        resources[name].provider = provider
      end
    end
  end

  def exists?
    @property_hash[:ensure] == :present
  end

  def create
    @property_flush[:ensure] = :present
    set_parameter
  end

  def destroy
    @property_flush[:ensure] = :absent
    set_parameter
  end

  def set_parameter
    vhost = resource[:name].rpartition('@').last
    key = resource[:name].rpartition('@').first

    if @property_flush[:ensure] == :absent
      rabbitmqctl('clear_parameter', '-p', vhost, resource[:component_name], key)
    else
      rabbitmqctl('set_parameter', '-p', vhost, resource[:component_name], key, resource[:value].to_json)
    end
  end
end

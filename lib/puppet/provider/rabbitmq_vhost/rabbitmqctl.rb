# frozen_string_literal: true

require File.expand_path(File.join(File.dirname(__FILE__), '..', 'rabbitmq_cli'))
Puppet::Type.type(:rabbitmq_vhost).provide(
  :rabbitmqctl,
  parent: Puppet::Provider::RabbitmqCli
) do
  confine feature: :posix

  def self.prefetch(resources)
    instances.each do |prov|
      if (resource = resources[prov.name])
        resource.provider = prov
      end
    end
  end

  # To maintain compatibility with older versions of RabbitMQ,
  # we only deal with vhost metadata >= version 3.11.0
  def self.supports_metadata?
    Puppet::Util::Package.versioncmp(rabbitmq_version, '3.11') >= 0
  end

  def supports_metadata?
    self.class.supports_metadata?
  end

  def self.vhost_list
    run_with_retries do
      if supports_metadata?
        rabbitmqctl_list('vhosts', 'name,description,default_queue_type,tags', '-s')
      else
        rabbitmqctl_list('vhosts')
      end
    end
  end

  def self.instances
    vhost_list.split(%r{\n}).map do |line|
      if supports_metadata?
        raise Puppet::Error, "Cannot parse invalid vhost line: #{line}" unless \
          (matches = line.match(%r{^(\S+)\t+(.*?)\t+(undefined|quorum|classic|stream)?\t+\[(.*?)\]$}i))

        name, description, default_queue_type, tags = matches.captures
        # RMQ returns 'undefined' as default_queue_type if it has never been set
        default_queue_type = nil if default_queue_type == 'undefined'
        new(ensure: :present, name: name, description: description, default_queue_type: default_queue_type, tags: tags.split(%r{,\s*}))
      else
        raise Puppet::Error, "Cannot parse invalid vhost line: #{line}" unless line =~ %r{^(\S+)$}

        new(ensure: :present, name: Regexp.last_match(1))
      end
    end
  end

  def create
    rabbitmqctl('add_vhost', *params)
  end

  def params
    params = [resource[:name]]
    if supports_metadata?
      params << ['--description', resource[:description]] if resource[:description]
      params << ['--default-queue-type', resource[:default_queue_type]] if resource[:default_queue_type] && resource[:default_queue_type] != 'undefined'
      params << ['--tags', resource[:tags].join(',')] if resource[:tags]
    end
    params
  end

  def description
    @property_hash[:description]
  end

  def tags
    @property_hash[:tags]
  end

  def default_queue_type
    @property_hash[:default_queue_type]
  end

  def tags=(tags)
    @property_hash[:tags] = tags
  end

  def description=(value)
    @property_hash[:description] = value
  end

  def default_queue_type=(value)
    @property_hash[:default_queue_type] = value
  end

  def flush
    return if @property_hash.empty? || !supports_metadata? || !exists?

    params = [resource[:name]]
    params << ['--description', @property_hash[:description]] if @property_hash[:description]
    params << ['--default-queue-type', @property_hash[:default_queue_type]] if @property_hash[:default_queue_type]
    params << ['--tags', @property_hash[:tags].join(',')] if @property_hash[:tags]
    rabbitmqctl('update_vhost_metadata', *params)
  end

  def destroy
    rabbitmqctl('delete_vhost', resource[:name])
  end

  def exists?
    run_with_retries { rabbitmqctl_list('vhosts') }.split(%r{\n}).include? resource[:name]
  end
end

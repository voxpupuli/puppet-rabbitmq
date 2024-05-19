# frozen_string_literal: true

require File.expand_path(File.join(File.dirname(__FILE__), '..', 'rabbitmq_cli'))
Puppet::Type.type(:rabbitmq_cluster).provide(
  :rabbitmqctl,
  parent: Puppet::Provider::RabbitmqCli
) do
  desc 'Rabbitmqctl provider for rabbitmq cluster'
  confine feature: :posix

  def exists?
    cluster_name == @resource[:name].to_s
  end

  def create
    storage_type = @resource[:node_disc_type].to_s

    init_node = @resource[:init_node].to_s.gsub(%r{^.*@}, '')
    local_node = @resource[:local_node].to_s.gsub(%r{^.*@}, '')

    if local_node == init_node || [Facter.value(:networking)['hostname'], Facter.value(:networking)['fqdn']].include?(init_node)
      return rabbitmqctl('set_cluster_name', @resource[:name]) unless cluster_name == resource[:name].to_s
    else
      rabbitmqctl('stop_app')
      rabbitmqctl('join_cluster', "rabbit@#{init_node}", "--#{storage_type}")
      rabbitmqctl('start_app')
    end
  end

  def destroy
    rabbitmqctl('stop_app')
    rabbitmqctl('reset')
    rabbitmqctl('start_app')
  end

  def cluster_name
    cluster_status = rabbitmqctl('-q', 'cluster_status')
    [%r!{cluster_name,<<"(\S+)">>}!, %r{^Cluster name: (\S+)$}].each do |r|
      if (data = r.match(cluster_status))
        return data[1]
      end
    end
  end
end

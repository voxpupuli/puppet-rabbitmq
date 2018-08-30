require File.expand_path(File.join(File.dirname(__FILE__), '..', 'rabbitmqctl'))
Puppet::Type.type(:rabbitmq_cluster).provide(
  :rabbitmqctl,
  parent: Puppet::Provider::Rabbitmqctl
) do
  has_command(:rabbitmqctl, 'rabbitmqctl') do
    environment HOME: '/tmp'
  end

  confine feature: :posix

  def exists?
    cluster_status = rabbitmqctl('-q', 'cluster_status')
    cluster_name = %r{^ {cluster_name,<<"(.*)">>},}.match(cluster_status)[1]
    return true if cluster_name == @resource[:name].to_s
  end

  def create
    storage_type = @resource[:node_disc_type].to_s
    node_name = Facter.value(:fqdn)
    init_node = @resource[:init_node].to_s.split('@')[1] unless @resource[:init_node].nil?
    if node_name == init_node
      cluster_status = rabbitmqctl('-q', 'cluster_status')
      cluster_name = %r{^ {cluster_name,<<"(.*)">>},}.match(cluster_status)[1]
      rabbitmqctl('set_cluster_name', @resource[:name]) unless cluster_name == resource[:name].to_s
    else
      rabbitmqctl('stop_app')
      rabbitmqctl('join_cluster', @resource[:init_node].to_s, "--#{storage_type}")
      rabbitmqctl('start_app')
    end
  end

  def destroy
    rabbitmqctl('stop_app')
    rabbitmqctl('reset')
    rabbitmqctl('start_app')
  end
end

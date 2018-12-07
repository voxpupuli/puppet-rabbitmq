# @summary Backwards compatibility layer to support including `rabbitmq::server` directly.
#
# This module manages the installation and config of the rabbitmq server. It is used as backward compability layer for modules which
#   require rabbitmq::server instead of rabbitmq class.
#
# @param port
#   Port that rabbitmq server should listen to
# @param delete_guest_user
#   Whether or not to delete the default user
# @param package_name
#   Name of rabbitmq package
# @param service_name
#   Name of rabbitmq service
# @param service_ensure
#   Desired ensure state for service
# @param service_manage
#   Determines if the service is managed
# @param config_stomp
#   Enable or disable stomp
# @param stomp_port
#   Port stomp should be listening on
# @param node_ip_address
#   IP address for rabbitmq to bind to
# @param config
#   Contents of config file
# @param env_config
#   Contents of env-config file
# @param config_cluster
#   Whether to configure a RabbitMQ cluster
# @param cluster_nodes
#   Which nodes to cluster with (including the current one)
# @param cluster_node_type
#   Type of cluster node (disc/disk or ram)
# @param erlang_cookie
#   Erlang cookie, must be the same for all nodes in a cluster
# @param wipe_db_on_cookie_change
#   Whether to wipe the RabbitMQ data if the specified erlang_cookie differs from the current one. This is a sad parameter: actually, if
#   the cookie indeed differs, then wiping the database is the *only* thing you can do.  You're only required to set this parameter to
#   true as a sign that you realise this.
#
class rabbitmq::server(
  Integer $port                                  = $rabbitmq::params::port,
  Boolean $delete_guest_user                     = $rabbitmq::params::delete_guest_user,
  Variant[String, Array] $package_name           = $rabbitmq::params::package_name,
  String $service_name                           = $rabbitmq::params::service_name,
  Enum['running', 'stopped'] $service_ensure     = $rabbitmq::params::service_ensure,
  Boolean $service_manage                        = $rabbitmq::params::service_manage,
  Boolean $config_stomp                          = $rabbitmq::params::config_stomp,
  Integer[1, 65535] $stomp_port                  = $rabbitmq::params::stomp_port,
  Boolean $config_cluster                        = $rabbitmq::params::config_cluster,
  Array $cluster_nodes                           = $rabbitmq::params::cluster_nodes,
  Enum['ram', 'disk', 'disc'] $cluster_node_type = $rabbitmq::params::cluster_node_type,
  Optional[String] $node_ip_address              = $rabbitmq::params::node_ip_address,
  String $config                                 = $rabbitmq::params::config,
  String $env_config                             = $rabbitmq::params::env_config,
  Optional[String] $erlang_cookie                = $rabbitmq::params::erlang_cookie,
  Boolean $wipe_db_on_cookie_change              = $rabbitmq::params::wipe_db_on_cookie_change,
) inherits rabbitmq::params {

  class { 'rabbitmq':
    port                     => $port,
    delete_guest_user        => $delete_guest_user,
    package_name             => $package_name,
    service_name             => $service_name,
    service_ensure           => $service_ensure,
    service_manage           => $service_manage,
    config_stomp             => $config_stomp,
    stomp_port               => $stomp_port,
    config_cluster           => $config_cluster,
    cluster_nodes            => $cluster_nodes,
    cluster_node_type        => $cluster_node_type,
    node_ip_address          => $node_ip_address,
    config                   => $config,
    env_config               => $env_config,
    erlang_cookie            => $erlang_cookie,
    wipe_db_on_cookie_change => $wipe_db_on_cookie_change,
  }
  contain rabbitmq
}

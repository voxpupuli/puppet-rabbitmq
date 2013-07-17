# Class: rabbitmq::server
#
# This module manages the installation and config of the rabbitmq server
#   it has only been tested on certain version of debian-ish systems
# Parameters:
#  [*port*] - port where rabbitmq server is hosted
#  [*delete_guest_user*] - rather or not to delete the default user
#  [*version*] - version of rabbitmq-server to install
#  [*package_name*] - name of rabbitmq package
#  [*service_name*] - name of rabbitmq service
#  [*service_ensure*] - desired ensure state for service
#  [*stomp_port*] - port stomp should be listening on
#  [*node_ip_address*] - ip address for rabbitmq to bind to
#  [*config*] - contents of config file
#  [*env_config*] - contents of env-config file
#  [*config_cluster*] - whether to configure a RabbitMQ cluster
#  [*config_mirrored_queues*] - whether to configure RabbitMQ mirrored queues within a Rabbit Cluster.
#  [*cluster_disk_nodes*] - DEPRECATED (use cluster_nodes instead)
#  [*cluster_nodes*] - which nodes to cluster with (including the current one)
#  [*cluster_node_type*] - Type of cluster node (disc or ram)
#  [*erlang_cookie*] - erlang cookie, must be the same for all nodes in a cluster
#  [*wipe_db_on_cookie_change*] - whether to wipe the RabbitMQ data if the specified
#    erlang_cookie differs from the current one. This is a sad parameter: actually,
#    if the cookie indeed differs, then wiping the database is the *only* thing you
#    can do. You're only required to set this parameter to true as a sign that you
#    realise this.
# Requires:
#  stdlib
# Sample Usage:
#
#
#
#
# [Remember: No empty lines between comments and class definition]
class rabbitmq::server(
  $port = '5672',
  $delete_guest_user = false,
  $package_name = 'rabbitmq-server',
  $version = 'UNSET',
  $service_name = 'rabbitmq-server',
  $service_ensure = 'running',
  $manage_service = true,
  $config_stomp = false,
  $stomp_port = '6163',
  $config_cluster = false,
  $config_mirrored_queues = false,
  $cluster_disk_nodes = [],
  $cluster_nodes = [],
  $cluster_node_type = 'disc',
  $node_ip_address = 'UNSET',
  $config='UNSET',
  $env_config='UNSET',
  $erlang_cookie='EOKOWXQREETZSHFNTPEY',
  $wipe_db_on_cookie_change=false
) inherits rabbitmq {

  validate_bool($delete_guest_user, $config_stomp)
  validate_re($port, '\d+')
  validate_re($stomp_port, '\d+')

  if $version == 'UNSET' {
    $version_real = '2.4.1'
    $pkg_ensure_real   = 'present'
  } else {
    $version_real = $version
    $pkg_ensure_real   = $version
  }
  if size($cluster_disk_nodes) > 0 {
    notify{"WARNING: The cluster_disk_nodes is depricated. Use cluster_nodes instead.":}
    $cluster_nodes_real = $cluster_disk_nodes
  } else {
    $cluster_nodes_real = $cluster_nodes
  }
  if $config == 'UNSET' {
    $config_real = template("${module_name}/rabbitmq.config")
  } else {
    $config_real = $config
  }
  if $env_config == 'UNSET' {
    $env_config_real = template("${module_name}/rabbitmq-env.conf.erb")
  } else {
    $env_config_real = $env_config
  }

  $plugin_dir = "/usr/lib/rabbitmq/lib/rabbitmq_server-${version_real}/plugins"

  file { '/etc/rabbitmq':
    ensure  => directory,
    owner   => '0',
    group   => '0',
    mode    => '0644',
  }

  file { 'rabbitmq.config':
    ensure  => file,
    path    => '/etc/rabbitmq/rabbitmq.config',
    content => $config_real,
    owner   => '0',
    group   => '0',
    mode    => '0644',
    notify  => Class['rabbitmq::service'],
  }

  if $config_cluster {
    file { 'erlang_cookie':
      path    => '/var/lib/rabbitmq/.erlang.cookie',
      owner   => 'rabbitmq',
      group   => 'rabbitmq',
      mode    => '0400',
      content => $erlang_cookie,
      replace => true,
      before  => File['rabbitmq.config'],
      require => Exec['wipe_db'],
    }
    # require authorize_cookie_change

    if $wipe_db_on_cookie_change {
      exec { 'wipe_db':
        command => '/etc/init.d/rabbitmq-server stop; /bin/rm -rf /var/lib/rabbitmq/mnesia',
        unless  => "/bin/grep -qx ${erlang_cookie} /var/lib/rabbitmq/.erlang.cookie"
      }
    } else {
      exec { 'wipe_db':
        command => '/bin/false "Cookie must be changed but wipe_db is false"', # If the cookie doesn't match, just fail.
        unless  => "/bin/grep -qx ${erlang_cookie} /var/lib/rabbitmq/.erlang.cookie"
      }
    }
  }

  file { 'rabbitmq-env.config':
    ensure  => file,
    path    => '/etc/rabbitmq/rabbitmq-env.conf',
    content => $env_config_real,
    owner   => '0',
    group   => '0',
    mode    => '0644',
    notify  => Class['rabbitmq::service'],
  }

  if $delete_guest_user {
    # delete the default guest user
    rabbitmq_user{ 'guest':
      ensure   => absent,
      provider => 'rabbitmqctl',
    }
  }

}

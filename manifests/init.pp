#
class rabbitmq(
  $admin_enable             = $rabbitmq::params::admin_enable,
  $cluster_disk_nodes       = $rabbitmq::params::cluster_disk_nodes,
  $cluster_node_type        = $rabbitmq::params::cluster_node_type,
  $cluster_nodes            = $rabbitmq::params::cluster_nodes,
  $config                   = $rabbitmq::params::config,
  $config_cluster           = $rabbitmq::params::config_cluster,
  $config_mirrored_queues   = $rabbitmq::params::config_mirrored_queues,
  $config_path              = $rabbitmq::params::config_path,
  $config_stomp             = $rabbitmq::params::config_stomp,
  $delete_guest_user        = $rabbitmq::params::delete_guest_user,
  $env_config               = $rabbitmq::params::env_config,
  $env_config_path          = $rabbitmq::params::env_config_path,
  $erlang_cookie            = $rabbitmq::params::erlang_cookie,
  $erlang_manage            = $rabbitmq::params::erlang_manage,
  $manage_service           = $rabbitmq::params::manage_service,
  $management_port          = $rabbitmq::params::management_port,
  $node_ip_address          = $rabbitmq::params::node_ip_address,
  $package_ensure           = $rabbitmq::params::package_ensure,
  $package_name             = $rabbitmq::params::package_name,
  $package_provider         = $rabbitmq::params::package_provider,
  $package_source           = $rabbitmq::params::package_source,
  $plugin_dir               = $rabbitmq::params::plugin_dir,
  $port                     = $rabbitmq::params::port,
  $service_ensure           = $rabbitmq::params::service_ensure,
  $service_manage           = $rabbitmq::params::service_manage,
  $service_name             = $rabbitmq::params::service_name,
  $stomp_port               = $rabbitmq::params::stomp_port,
  $version                  = $rabbitmq::params::version,
  $wipe_db_on_cookie_change = $rabbitmq::params::wipe_db_on_cookie_change,
) inherits rabbitmq::params {

  # Validate parameters.
  validate_bool($config_cluster)
  validate_bool($config_mirrored_queues)
  validate_bool($config_stomp)
  validate_bool($delete_guest_user)
  validate_bool($manage_service)
  validate_re($port, '\d+')
  validate_re($stomp_port, '\d+')

  # Handle deprecated option.
  if $cluster_disk_nodes {
    notify { 'cluster_disk_nodes':
      message => 'WARNING: The cluster_disk_nodes is deprecated.
       Use cluster_nodes instead.',
    }
    $cluster_nodes_real = $cluster_disk_nodes
  } else {
    $cluster_nodes_real = $cluster_nodes
  }

  if $erlang_manage {
    include '::erlang'
    Class['::erlang'] -> Class['::rabbitmq::install']
  }

  include '::rabbitmq::install'
  include '::rabbitmq::config'
  include '::rabbitmq::service'

  case $::osfamily {
    'RedHat':
      { include '::rabbitmq::repo::rhel' }
    'Debian':
      { include '::rabbitmq::repo::apt' }
    default:
      { }
  }

  if $admin_enable {
    include '::rabbitmq::install::rabbitmqadmin'

    rabbitmq_plugin { 'rabbitmq_management':
      ensure  => present,
      require => Class['rabbitmq::install'],
      notify  => Class['rabbitmq::service']
    }

    Class['::rabbitmq::service'] -> Class['::rabbitmq::install::rabbitmqadmin']
  }

  # Anchor this as per #8140 - this ensures that classes won't float off and
  # mess everything up.  You can read about this at:
  # http://docs.puppetlabs.com/puppet/2.7/reference/lang_containment.html#known-issues
  anchor { 'rabbitmq::begin': }
  anchor { 'rabbitmq::end': }

  Anchor['rabbitmq::begin'] -> Class['::rabbitmq::install']
    -> Class['::rabbitmq::config'] ~> Class['::rabbitmq::service']
    -> Anchor['rabbitmq::end']

}

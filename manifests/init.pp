  #
class rabbitmq(
  $admin_enable               = $rabbitmq::params::admin_enable,
  $cluster_disk_nodes         = $rabbitmq::params::cluster_disk_nodes,
  $cluster_node_type          = $rabbitmq::params::cluster_node_type,
  $cluster_nodes              = $rabbitmq::params::cluster_nodes,
  $config                     = $rabbitmq::params::config,
  $config_cluster             = $rabbitmq::params::config_cluster,
  $config_mirrored_queues     = $rabbitmq::params::config_mirrored_queues,
  $config_path                = $rabbitmq::params::config_path,
  $config_stomp               = $rabbitmq::params::config_stomp,
  $default_user               = $rabbitmq::params::default_user,
  $default_pass               = $rabbitmq::params::default_pass,
  $delete_guest_user          = $rabbitmq::params::delete_guest_user,
  $env_config                 = $rabbitmq::params::env_config,
  $env_config_path            = $rabbitmq::params::env_config_path,
  $erlang_cookie              = $rabbitmq::params::erlang_cookie,
  $erlang_manage              = $rabbitmq::params::erlang_manage,
  $manage_service             = $rabbitmq::params::manage_service,
  $management_port            = $rabbitmq::params::management_port,
  $node_ip_address            = $rabbitmq::params::node_ip_address,
  $package_apt_pin            = $rabbitmq::params::package_apt_pin,
  $package_ensure             = $rabbitmq::params::package_ensure,
  $package_gpg_key            = $rabbitmq::params::package_gpg_key,
  $package_name               = $rabbitmq::params::package_name,
  $package_provider           = $rabbitmq::params::package_provider,
  $package_source             = $rabbitmq::params::package_source,
  $plugin_dir                 = $rabbitmq::params::plugin_dir,
  $port                       = $rabbitmq::params::port,
  $service_ensure             = $rabbitmq::params::service_ensure,
  $service_manage             = $rabbitmq::params::service_manage,
  $service_name               = $rabbitmq::params::service_name,
  $ssl                        = $rabbitmq::params::ssl,
  $ssl_cacert                 = $rabbitmq::params::ssl_cacert,
  $ssl_cert                   = $rabbitmq::params::ssl_cert,
  $ssl_key                    = $rabbitmq::params::ssl_key,
  $ssl_management_port        = $rabbitmq::params::ssl_management_port,
  $ssl_stomp_port             = $rabbitmq::params::ssl_stomp_port,
  $stomp_port                 = $rabbitmq::params::stomp_port,
  $version                    = $rabbitmq::params::version,
  $wipe_db_on_cookie_change   = $rabbitmq::params::wipe_db_on_cookie_change,
  $cluster_partition_handling = $rabbitmq::params::cluster_partition_handling,
  $environment_variables      = $rabbitmq::params::environment_variables,
  $config_variables           = $rabbitmq::params::config_variables,
) inherits rabbitmq::params {

  validate_bool($admin_enable)
  validate_bool($erlang_manage)
  # Validate install parameters.
  validate_re($package_apt_pin, '^(|\d+)$')
  validate_string($package_ensure)
  validate_string($package_gpg_key)
  validate_string($package_name)
  validate_string($package_provider)
  validate_string($package_source)
  validate_re($version, '^\d+\.\d+\.\d+(-\d+)*$') # Allow 3 digits and optional -n postfix.
  # Validate config parameters.
  validate_array($cluster_disk_nodes)
  validate_re($cluster_node_type, '^(ram|disc)$')
  validate_array($cluster_nodes)
  validate_string($config)
  validate_absolute_path($config_path)
  validate_bool($config_cluster)
  validate_bool($config_mirrored_queues)
  validate_bool($config_stomp)
  validate_string($default_user)
  validate_string($default_pass)
  validate_bool($delete_guest_user)
  validate_string($env_config)
  validate_absolute_path($env_config_path)
  validate_string($erlang_cookie)
  validate_re($management_port, '\d+')
  validate_string($node_ip_address)
  validate_absolute_path($plugin_dir)
  validate_re($port, '\d+')
  validate_re($stomp_port, '\d+')
  validate_bool($wipe_db_on_cookie_change)
  # Validate service parameters.
  validate_bool($manage_service)
  validate_re($service_ensure, '^(running|stopped)$')
  validate_bool($service_manage)
  validate_string($service_name)
  validate_bool($ssl)
  validate_string($ssl_cacert)
  validate_string($ssl_cert)
  validate_string($ssl_key)
  validate_string($ssl_management_port)
  validate_re($ssl_management_port, '\d+')
  validate_string($ssl_stomp_port)
  validate_re($ssl_stomp_port, '\d+')
  validate_hash($environment_variables)
  validate_hash($config_variables)

  if $erlang_manage {
    include '::erlang'
    Class['::erlang'] -> Class['::rabbitmq::install']
  }

  include '::rabbitmq::install'
  include '::rabbitmq::config'
  include '::rabbitmq::service'
  include '::rabbitmq::management'

  case $::osfamily {
    'RedHat', 'SUSE':
      { include '::rabbitmq::repo::rhel' }
    'Debian':
      { include '::rabbitmq::repo::apt' }
    default:
      { }
  }

  if $admin_enable and $service_manage {
    include '::rabbitmq::install::rabbitmqadmin'

    rabbitmq_plugin { 'rabbitmq_management':
      ensure  => present,
      require => Class['rabbitmq::install'],
      notify  => Class['rabbitmq::service']
    }

    Class['::rabbitmq::service'] -> Class['::rabbitmq::install::rabbitmqadmin']
  }

  # Anchor this as per #8040 - this ensures that classes won't float off and
  # mess everything up.  You can read about this at:
  # http://docs.puppetlabs.com/puppet/2.7/reference/lang_containment.html#known-issues
  anchor { 'rabbitmq::begin': }
  anchor { 'rabbitmq::end': }

  Anchor['rabbitmq::begin'] -> Class['::rabbitmq::install']
    -> Class['::rabbitmq::config'] ~> Class['::rabbitmq::service']
    -> Class['::rabbitmq::management'] -> Anchor['rabbitmq::end']

  # Make sure the various providers have their requirements in place.
  Class['::rabbitmq::install'] -> Rabbitmq_plugin<| |>
  Class['::rabbitmq::install::rabbitmqadmin'] -> Rabbitmq_exchange<| |>

}

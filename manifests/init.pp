# rabbitmq
#
# @summary Main class for rabbitmq module
#
# @example Declaring the class
#   class { 'rabbitmq': }
#
# @param management_ip_address Allows you to set the IP for management interface to bind to separately. Set to 127.0.0.1 to bind to localhost only, or 0.0.0.0 to bind to all interfaces.
# @param node_ip_address Allows you to set the IP for RabbitMQ service to bind to. Set to 127.0.0.1 to bind to localhost only, or 0.0.0.0 to bind to all interfaces.
class rabbitmq(
  Boolean $admin_enable                          = $rabbitmq::params::admin_enable,
  Enum['ram', 'disk', 'disc'] $cluster_node_type = $rabbitmq::params::cluster_node_type,
  Array $cluster_nodes                           = $rabbitmq::params::cluster_nodes,
  String $config                                 = $rabbitmq::params::config,
  Boolean $config_cluster                        = $rabbitmq::params::config_cluster,
  Stdlib::Absolutepath $config_path              = $rabbitmq::params::config_path,
  Boolean $config_stomp                          = $rabbitmq::params::config_stomp,
  Boolean $config_shovel                         = $rabbitmq::params::config_shovel,
  Hash $config_shovel_statics                    = $rabbitmq::params::config_shovel_statics,
  String $default_user                           = $rabbitmq::params::default_user,
  String $default_pass                           = $rabbitmq::params::default_pass,
  Boolean $delete_guest_user                     = $rabbitmq::params::delete_guest_user,
  String $env_config                             = $rabbitmq::params::env_config,
  Stdlib::Absolutepath $env_config_path          = $rabbitmq::params::env_config_path,
  Optional[String] $erlang_cookie                = undef,
  Optional[String] $interface                    = undef,
  Optional[String] $management_ip_address        = undef,
  $management_port                               = $rabbitmq::params::management_port,
  Boolean $management_ssl                        = $rabbitmq::params::management_ssl,
  Optional[String] $management_hostname          = undef,
  Optional[String] $node_ip_address              = undef,
  $package_apt_pin                               = $rabbitmq::params::package_apt_pin,
  String $package_ensure                         = $rabbitmq::params::package_ensure,
  String $package_gpg_key                        = $rabbitmq::params::package_gpg_key,
  String $package_name                           = $rabbitmq::params::package_name,
  Optional[String] $package_source               = undef,
  Optional[String] $package_provider             = undef,
  Boolean $repos_ensure                          = $rabbitmq::params::repos_ensure,
  $manage_repos                                  = undef,
  $rabbitmq_user                                 = $rabbitmq::params::rabbitmq_user,
  $rabbitmq_group                                = $rabbitmq::params::rabbitmq_group,
  $rabbitmq_home                                 = $rabbitmq::params::rabbitmq_home,
  Integer $port                                  = $rabbitmq::params::port,
  Boolean $tcp_keepalive                         = $rabbitmq::params::tcp_keepalive,
  Integer $tcp_backlog                           = $rabbitmq::params::tcp_backlog,
  Optional[Integer] $tcp_sndbuf                  = undef,
  Optional[Integer] $tcp_recbuf                  = undef,
  Optional[Integer] $heartbeat                   = undef,
  Enum['running', 'stopped'] $service_ensure     = $rabbitmq::params::service_ensure,
  Boolean $service_manage                        = $rabbitmq::params::service_manage,
  String $service_name                           = $rabbitmq::params::service_name,
  Boolean $ssl                                   = $rabbitmq::params::ssl,
  Boolean $ssl_only                              = $rabbitmq::params::ssl_only,
  Optional[String] $ssl_cacert                   = undef,
  Optional[String] $ssl_cert                     = undef,
  Optional[String] $ssl_key                      = undef,
  Optional[Integer] $ssl_depth                   = undef,
  Optional[String] $ssl_cert_password            = undef,
  $ssl_port                                      = $rabbitmq::params::ssl_port,
  Optional[String] $ssl_interface                = undef,
  Integer $ssl_management_port                   = $rabbitmq::params::ssl_management_port,
  Integer $ssl_stomp_port                                = $rabbitmq::params::ssl_stomp_port,
  $ssl_verify                                    = $rabbitmq::params::ssl_verify,
  $ssl_fail_if_no_peer_cert                      = $rabbitmq::params::ssl_fail_if_no_peer_cert,
  Optional[Array] $ssl_versions                  = undef,
  Array $ssl_ciphers                             = $rabbitmq::params::ssl_ciphers,
  Boolean $stomp_ensure                          = $rabbitmq::params::stomp_ensure,
  Boolean $ldap_auth                             = $rabbitmq::params::ldap_auth,
  String $ldap_server                            = $rabbitmq::params::ldap_server,
  String $ldap_user_dn_pattern                   = $rabbitmq::params::ldap_user_dn_pattern,
  String $ldap_other_bind                        = $rabbitmq::params::ldap_other_bind,
  Boolean $ldap_use_ssl                          = $rabbitmq::params::ldap_use_ssl,
  $ldap_port                                     = $rabbitmq::params::ldap_port,
  Boolean $ldap_log                              = $rabbitmq::params::ldap_log,
  Hash $ldap_config_variables                    = $rabbitmq::params::ldap_config_variables,
  Integer $stomp_port                            = $rabbitmq::params::stomp_port,
  Boolean $stomp_ssl_only                        = $rabbitmq::params::stomp_ssl_only,
  Optional[String] $version                      = undef,
  Boolean $wipe_db_on_cookie_change              = $rabbitmq::params::wipe_db_on_cookie_change,
  $cluster_partition_handling                    = $rabbitmq::params::cluster_partition_handling,
  Variant[Integer, String] $file_limit           = $rabbitmq::params::file_limit,
  Hash $environment_variables                    = $rabbitmq::params::environment_variables,
  Hash $config_variables                         = $rabbitmq::params::config_variables,
  Hash $config_kernel_variables                  = $rabbitmq::params::config_kernel_variables,
  Hash $config_management_variables              = $rabbitmq::params::config_management_variables,
  Hash $config_additional_variables              = $rabbitmq::params::config_additional_variables,
  Optional[Array] $auth_backends                 = undef,
  $key_content                                   = undef,
  Optional[Integer] $collect_statistics_interval = undef,
  Boolean $ipv6                                  = $rabbitmq::params::ipv6,
  String $inetrc_config                          = $rabbitmq::params::inetrc_config,
  Stdlib::Absolutepath $inetrc_config_path       = $rabbitmq::params::inetrc_config_path,
) inherits rabbitmq::params {

  # Validate install parameters.
  validate_re($package_apt_pin, '^(|\d+)$')

  # using sprintf for conversion to string, because "${file_limit}" doesn't
  # pass lint, despite being nicer
  validate_re(sprintf('%s', $file_limit),
              '^(\d+|-1|unlimited|infinity)$', '$file_limit must be a positive integer, \'-1\', \'unlimited\', or \'infinity\'.')

  if $ssl_only and ! $ssl {
    fail('$ssl_only => true requires that $ssl => true')
  }

  if $config_stomp and $stomp_ssl_only and ! $ssl_stomp_port  {
    fail('$stomp_ssl_only requires that $ssl_stomp_port be set')
  }

  if $ssl_versions {
    unless $ssl {
      fail('$ssl_versions requires that $ssl => true')
    }
  }

  if $package_source != undef {
    warning('$package_source is now deprecated. Please use yum installation or handle outside of this module.')
  }

  if $package_provider != undef {
    warning('$package_provider is now deprecated. Please use yum installation or handle outside of this module.')
  }

  if $manage_repos != undef {
    warning('$manage_repos is now deprecated. Please use $repos_ensure instead.')
  }

  if $version != undef {
    warning('$version is now deprecated, and will not have any effect. If you need to pin to a particular version, use $package_ensure')
  }

  if $repos_ensure {
    case $::osfamily {
      'RedHat': {
        class { '::rabbitmq::repo::rhel':
          key_source  => $package_gpg_key,
        }
      }
      'Debian': {
        class { '::rabbitmq::repo::apt' :
          key_source  => $package_gpg_key,
          key_content => $key_content,
        }
      }
      default: {
      }
    }
  }

  include '::rabbitmq::install'
  include '::rabbitmq::config'
  include '::rabbitmq::service'
  include '::rabbitmq::management'

  if $admin_enable and $service_manage {
    include '::rabbitmq::install::rabbitmqadmin'

    rabbitmq_plugin { 'rabbitmq_management':
      ensure   => present,
      require  => Class['rabbitmq::install'],
      notify   => Class['rabbitmq::service'],
      provider => 'rabbitmqplugins',
    }

    Class['::rabbitmq::service'] -> Class['::rabbitmq::install::rabbitmqadmin']
    Class['::rabbitmq::install::rabbitmqadmin'] -> Rabbitmq_exchange<| |>
  }

  if $stomp_ensure {
    rabbitmq_plugin { 'rabbitmq_stomp':
      ensure  => present,
      require => Class['rabbitmq::install'],
      notify  => Class['rabbitmq::service'],
    }
  }

  if ($ldap_auth) {
    rabbitmq_plugin { 'rabbitmq_auth_backend_ldap':
      ensure  => present,
      require => Class['rabbitmq::install'],
      notify  => Class['rabbitmq::service'],
    }
  }

  if ($config_shovel) {
    rabbitmq_plugin { 'rabbitmq_shovel':
      ensure   => present,
      require  => Class['rabbitmq::install'],
      notify   => Class['rabbitmq::service'],
      provider => 'rabbitmqplugins',
    }

    if ($admin_enable) {
      rabbitmq_plugin { 'rabbitmq_shovel_management':
        ensure   => present,
        require  => Class['rabbitmq::install'],
        notify   => Class['rabbitmq::service'],
        provider => 'rabbitmqplugins',
      }
    }
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

}

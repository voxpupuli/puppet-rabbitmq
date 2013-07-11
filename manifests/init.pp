class rabbitmq(
  $admin_enable     = $rabbitmq::params::admin_enable,
  $erlang_manage    = $rabbitmq::params::erlang_manage,
  $management_port  = $rabbitmq::params::management_port,
  $package_ensure   = $rabbitmq::params::package_ensure,
  $package_name     = $rabbitmq::params::package_name,
  $package_provider = $rabbitmq::params::package_provider,
  $package_source   = $rabbitmq::params::package_source,
  $relversion       = $rabbitmq::params::relversion,
  $service_ensure   = $rabbitmq::params::service_ensure,
  $service_manage   = $rabbitmq::params::service_manage,
  $service_name     = $rabbitmq::params::service_name,
  $version          = $rabbitmq::params::version,
) inherits rabbitmq::params {

  if $erlang_manage {
    include '::erlang'
    Class['::erlang'] -> Class['::rabbitmq::install']
  }

  include '::rabbitmq::install'
  include '::rabbitmq::server'
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
    -> Class['::rabbitmq::server'] ~> Class['::rabbitmq::service']
    -> Anchor['rabbitmq::end']

}

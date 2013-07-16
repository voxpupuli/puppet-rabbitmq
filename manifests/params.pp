# Class: rabbitmq::params
#
#   The RabbitMQ Module configuration settings.
#
class rabbitmq::params {

  $admin_enable    = true
  $erlang_manage   = false
  $management_port = '15672'
  $service_ensure  = 'running'
  $service_manage  = true
  $service_name    = 'rabbitmq-server'

  case $::osfamily {
    'Debian': {
      $package_ensure   = 'installed'
      $package_name     = 'rabbitmq-server'
      $package_provider = 'apt'
      $package_source   = false
      $version          = '3.1.3'
    }
    'RedHat': {
      $package_ensure   = 'installed'
      $package_name     = 'rabbitmq-server'
      $package_provider = 'rpm'
      $version          = '3.1.3-1'
      $base_version     = regsubst($version,'^(.*)-\d$','\1')
      # This must remain at the end as we need $base_version and $version defined first.
      $package_source   = "http://www.rabbitmq.com/releases/rabbitmq-server/v${base_version}/rabbitmq-server-${version}.noarch.rpm"
    }
    default: {
      fail("The ${module_name} module is not supported on an ${::osfamily} based system.")
    }
  }

}

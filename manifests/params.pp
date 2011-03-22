# Class: rabbitmq::params
#
#   This class provides parameters for the rabbitmq module.
#
#   Jeff McCune <jeff@puppetlabs.com>
#
#   The intention is to subclass this class to bring the variables into scope.
#
# Parameters:
#
#   version: 2.3.1
#
# Actions:
#
# Requires:
#
# Sample Usage:
#
#   class rabbitmq inherits rabbitmq::params { }
#
class rabbitmq::params(
  $version = 'UNSET'
) {

  # This is the RabbitMQ Server Version
  if $version == 'UNSET' {
    $version_real = '2.3.1'
    $pkg_ensure   = 'present'
  } else {
    $version_real = $version
    $pkg_ensure   = $version
  }

  case $operatingsystem {
    centos, redhat, oel: {
      $packages = 'rabbitmq-server'
      $service  = 'rabbitmq-server'
      $plugin_dir = "/usr/lib/rabbitmq/lib/rabbitmq_server-${version_real}/plugins"
    }
    default: {
      fail("operatingsystem $operatingsystem is not supported")
    }
  }

}


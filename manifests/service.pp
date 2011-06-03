# Class: rabbitmq::service
#
#   This class manages the rabbitmq server service itself.
#
#   Jeff McCune <jeff@puppetlabs.com>
#
#
# Parameters:
#
# Actions:
#
# Requires:
#
# Sample Usage:
#
class rabbitmq::service(
  $service_name = 'rabbitmq',
  $ensure='UNSET'
) {

  $service_name_real = $service_name 

  if $ensure in [ 'UNSET', 'running' ] {
    $ensure_real = 'running'
    $enable_real = true
  } elsif $ensure == 'stopped' {
    $ensure_real = 'stopped'
    $enable_real = false
  } else {
    fail("ensure parameter must be running or stopped, got: $ensure")
  }

  service { $service_name_real:
    ensure     => $ensure_real,
    enable     => $enable_real,
    hasstatus  => true,
    hasrestart => true,
  }

}

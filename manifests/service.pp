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
  $ensure         = 'running',
  $service_name   = 'rabbitmq-server',
  $manage_service = true
) {

  validate_re($ensure, '^(running|stopped)$')
  validate_bool($manage_service)
  if ($manage_service) {
    if $ensure == 'running' {
      Class['rabbitmq::service'] -> Rabbitmq_user<| |>
      Class['rabbitmq::service'] -> Rabbitmq_vhost<| |>
      Class['rabbitmq::service'] -> Rabbitmq_user_permissions<| |>
      $ensure_real = 'running'
      $enable_real = true
    } else {
      $ensure_real = 'stopped'
      $enable_real = false
    }

    service { $service_name:
      ensure     => $ensure_real,
      enable     => $enable_real,
      hasstatus  => true,
      hasrestart => true,
    }
  }

}

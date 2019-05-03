# @summary
#   This class handles the RabbitMQ service.
#
# @api private
#
class rabbitmq::service {

  assert_private()

  if ($rabbitmq::service_manage) {
    if $rabbitmq::service_ensure == 'running' {
      $ensure_real = 'running'
      $enable_real = true
    } else {
      $ensure_real = 'stopped'
      $enable_real = false
    }

    service { 'rabbitmq-server':
      ensure     => $ensure_real,
      enable     => $enable_real,
      hasstatus  => true,
      hasrestart => true,
      name       => $rabbitmq::service_name,
    }

    if $facts['systemd'] {
      Class['systemd::systemctl::daemon_reload'] -> Service['rabbitmq-server']
    }
  }
}

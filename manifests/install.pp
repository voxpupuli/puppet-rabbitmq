# @summary
#   This class handles the RabbitMQ package.
#
# @api private
#
class rabbitmq::install {

  assert_private()

  package { $rabbitmq::package_name:
    ensure => $rabbitmq::package_ensure,
    notify => Class['rabbitmq::service'],
  }

  if $rabbitmq::environment_variables['MNESIA_BASE'] {
    file { $rabbitmq::environment_variables['MNESIA_BASE']:
      ensure  => 'directory',
      owner   => 'root',
      group   => $rabbitmq::rabbitmq_group,
      mode    => '0775',
      require => Package[$rabbitmq::package_name],
    }
  }
}

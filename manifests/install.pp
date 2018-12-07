# Ensures that rabbitmq-server exists
#
# @api private
class rabbitmq::install {

  $package_ensure   = $rabbitmq::package_ensure
  $package_name     = $rabbitmq::package_name
  $rabbitmq_group   = $rabbitmq::rabbitmq_group

  package { $package_name:
    ensure => $package_ensure,
    notify => Class['rabbitmq::service'],
  }

  if $rabbitmq::environment_variables['MNESIA_BASE'] {
    file { $rabbitmq::environment_variables['MNESIA_BASE']:
      ensure  => 'directory',
      owner   => 'root',
      group   => $rabbitmq_group,
      mode    => '0775',
      require => Package[$package_name],
    }
  }
}

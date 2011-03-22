# Class: rabbitmq
#
# This module manages rabbitmq
#
# Parameters:
#
# Actions:
#
# Requires:
#
# Sample Usage:
#
# [Remember: No empty lines between comments and class definition]
class rabbitmq($config='UNSET') inherits rabbitmq::params {

  if $config == 'UNSET' {
    $config_real = template("${module_name}/rabbitmq.conf")
  } else {
    $config_real = $config
  }

  package { $packages:
    ensure => $pkg_ensure,
    notify => Class['rabbitmq::service'],
    before => File['rabbitmq.conf'],
  }

  file { '/etc/rabbitmq':
    ensure  => directory,
    owner   => '0',
    group   => '0',
    mode    => '0644',
    require => Package[$packages],
  }

  file { 'rabbitmq.conf':
    ensure  => file,
    path    => '/etc/rabbitmq/rabbitmq.conf',
    content => $config_real,
    owner   => '0',
    group   => '0',
    mode    => '0644',
    notify  => Class['rabbitmq::service'],
  }

}

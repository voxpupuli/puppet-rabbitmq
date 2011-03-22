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

  File {
    owner => '0',
    group => '0',
    mode  => '0644',
  }

  package { $packages:
    ensure => $pkg_ensure,
    notify => Service["${service}"],
    before => File['rabbitmq.conf'],
  }

  file { 'rabbitmq.conf':
    ensure  => file,
    path    => '/etc/rabbitmq/rabbitmq.conf',
    content => $config_real,
    notify  => Service["${service}"],
  }

  service { $service:
    ensure     => running,
    enable     => true,
    hasstatus  => true,
    hasrestart => true,
  }

}

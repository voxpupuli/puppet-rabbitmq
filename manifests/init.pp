# Class: rabbitmq
#
# This module manages rabbitmq
#   it is known to work on certain versions of redhat-ish and debian-ish systems
# Parameters:
#  [*port*]
#  [*delete_guest_user*] - rather or not to remove the default user
# Actions:
#
# Requires:
#
# Sample Usage:
#
# [Remember: No empty lines between comments and class definition]
class rabbitmq(
  $port = '5672',
  $delete_guest_user = false,
  $package_name = 'rabbitmq-server',
  $version = 'UNSET',
  $service_name = 'rabbitmq-server',
  $service_ensure = 'running',
  $install_stomp = false,
  $stomp_port = '6163',
  $stomp_package = 'rabbitmq-plugin-stomp',
  $config='UNSET',
  $env_config='UNSET'
) {

  $port_real = $port
  $package_name_real = $package_name
  $service_name_real = $service_name
  $service_ensure_real = $service_ensure
  $stomp_package_real = $stomp_package
  if ! ($install_stomp in [true, false]) {
    $install_stomp_real = $install_stomp
  } else {
    fail("Invalid value for install_stomp ${install_stomp}, must be (true|false)")
  }
  if ! ($install_stomp in [true, false]) {
    $install_stomp_real = $install_stomp
  } else {
    fail("Invalid value for install_stomp ${install_stomp}, must be (true|false)")
  }

  if $stomp_port =~ /\d+/ {
    $stomp_port_real = $stomp_port
  } else {
    fail("Stomp Port must be a number!  Got: $stomp_port")
  }

  if $config == 'UNSET' {
    $config_real = template("${module_name}/rabbitmq.config")
  } else {
    $config_real = $config
  }
  if $env_config == 'UNSET' {
    $env_config_real = template("${module_name}/rabbitmq-env.conf.erb")
  } else {
    $env_config_real = $env_config
  }
  if $version == 'UNSET' {
    $version_real = '2.4.1'
    $pkg_ensure_real   = 'present'
  } else {
    $version_real = $version
    $pkg_ensure_real   = $version
  }

  $plugin_dir_real = "/usr/lib/rabbitmq/lib/rabbitmq_server-${version_real}/plugins"

  package { $package_name_real:
    ensure => $pkg_ensure_real,
    notify => Class['rabbitmq::service'],
  }

  if $install_stomp_real {
    package { $stomp_package_real:
      ensure => installed,
      notify => Class['rabbitmq::service'],
      before => File['rabbitmq.config'],
    }
    file { 'rabbitmq.config':
      ensure  => file,
      path    => '/etc/rabbitmq/rabbitmq.config',
      content => $config_real,
      owner   => '0',
      group   => '0',
      mode    => '0644',
      notify  => Class['rabbitmq::service'],
      require => Package[$package_name_real]
    }
  }

  file { '/etc/rabbitmq':
    ensure  => directory,
    owner   => '0',
    group   => '0',
    mode    => '0644',
    require => Package[$package_name_real],
  }

  file { 'rabbitmq-env.config':
    ensure  => file,
    path    => '/etc/rabbitmq/rabbitmq-env.conf',
    content => $env_config_real,
    owner   => '0',
    group   => '0',
    mode    => '0644',
    notify  => Class['rabbitmq::service'],
  }

  class { 'rabbitmq::service':
    service_name => $service_name_real,
    ensure => $service_ensure_real,
  }

  if $delete_guest_user {
    # delete the default guest user
    rabbitmq_user{ 'guest':
      ensure  => absent,
      require => Class['rabbitmq::service']
    }
  }

}

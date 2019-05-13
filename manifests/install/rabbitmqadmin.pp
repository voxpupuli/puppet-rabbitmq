# @summary
#   This class handles the RabbitMQ admin package.
#
# @api private
#
class rabbitmq::install::rabbitmqadmin {

  assert_private()

  if $rabbitmq::rabbitmqadmin_package {
    package { 'rabbitmqadmin':
      ensure => 'present',
      name   => $rabbitmq::rabbitmqadmin_package,
    }
  } else {
    # Some systems (e.g., Ubuntu 16.04) don't ship Python 2 by default
    if $rabbitmq::manage_python {
      ensure_packages([$rabbitmq::params::python_package])
      $rabbitmqadmin_require = [
        Archive['rabbitmqadmin'],
        Package[$rabbitmq::params::python_package]
      ]
    } else {
      $rabbitmqadmin_require = Archive['rabbitmqadmin']
    }

    if($rabbitmq::ssl and $rabbitmq::management_ssl) {
      $management_port = $rabbitmq::ssl_management_port
      $protocol        = 'https'
    } else {
      $management_port = $rabbitmq::management_port
      $protocol        = 'http'
    }

    if !($rabbitmq::management_ip_address) {
      # Pull from localhost if we don't have an explicit bind address
      $sanitized_ip = '127.0.0.1'
    } elsif $rabbitmq::management_ip_address =~ Stdlib::Compat::Ipv6 {
      $sanitized_ip = join(enclose_ipv6(any2array($rabbitmq::management_ip_address)), ',')
    } else {
      $sanitized_ip = $rabbitmq::management_ip_address
    }

    if !($rabbitmq::use_config_file_for_plugins) {
      $rabbitmqadmin_archive_require = [
        Class['rabbitmq::service'],
        Rabbitmq_plugin['rabbitmq_management']
      ]
    } else {
      $rabbitmqadmin_archive_require = [
        Class['rabbitmq::service'],
        File['enabled_plugins']
      ]
    }

    archive { 'rabbitmqadmin':
      path             => "${rabbitmq::rabbitmq_home}/rabbitmqadmin",
      source           => "${protocol}://${sanitized_ip}:${management_port}/cli/rabbitmqadmin",
      username         => $rabbitmq::default_user,
      password         => $rabbitmq::default_pass,
      allow_insecure   => true,
      download_options => $rabbitmq::archive_options,
      cleanup          => false,
      require          => $rabbitmqadmin_archive_require,
    }

    file { '/usr/local/bin/rabbitmqadmin':
      owner   => 'root',
      group   => 'root',
      source  => "${rabbitmq::rabbitmq_home}/rabbitmqadmin",
      mode    => '0755',
      require => $rabbitmqadmin_require,
    }
  }
}

# Install rabbitmq admin
#
# @api private
class rabbitmq::install::rabbitmqadmin {
  if $rabbitmq::rabbitmqadmin_package {
    package { 'rabbitmqadmin':
      ensure => 'present',
      name   => $rabbitmq::rabbitmqadmin_package,
    }
  } else {
    $python_package = $rabbitmq::python_package
    # Some systems (e.g., Ubuntu 16.04) don't ship Python 2 by default
    if $rabbitmq::manage_python {
      ensure_packages([$python_package])
      $rabbitmqadmin_require = [Archive['rabbitmqadmin'], Package[$python_package]]
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

    $default_user = $rabbitmq::default_user
    $default_pass = $rabbitmq::default_pass
    $archive_options = $rabbitmq::archive_options

    # This should be consistent with rabbitmq::config
    if $rabbitmq::management_ip_address {
      $management_ip_address = $rabbitmq::management_ip_address
    } else {
      $management_ip_address = $rabbitmq::node_ip_address
    }

    if !($management_ip_address) {
      # Pull from localhost if we don't have an explicit bind address
      $sanitized_ip = '127.0.0.1'
    } elsif $management_ip_address =~ Stdlib::IP::Address::V6::Nosubnet {
      $sanitized_ip = join(enclose_ipv6(any2array($management_ip_address)), ',')
    } else {
      $sanitized_ip = $management_ip_address
    }

    if !($rabbitmq::use_config_file_for_plugins) {
      $rabbitmqadmin_archive_require = [
        Class['rabbitmq::service'],
        Rabbitmq_plugin['rabbitmq_management'],
        Exec['remove_old_rabbitmqadmin_on_upgrade']
      ]
    } else {
      $rabbitmqadmin_archive_require = [
        Class['rabbitmq::service'],
        File['enabled_plugins'],
        Exec['remove_old_rabbitmqadmin_on_upgrade']
      ]
    }

    Exec { 'remove_old_rabbitmqadmin_on_upgrade':
      path        => ['/bin','/usr/bin','/sbin','/usr/sbin'],
      command     => "rm ${rabbitmq::rabbitmq_home}/rabbitmqadmin",
      onlyif      => ["test -f ${rabbitmq::rabbitmq_home}/rabbitmqadmin"],
      refreshonly => true,
    }

    archive { 'rabbitmqadmin':
      path             => "${rabbitmq::rabbitmq_home}/rabbitmqadmin",
      source           => "${protocol}://${sanitized_ip}:${management_port}/cli/rabbitmqadmin",
      username         => $default_user,
      password         => $default_pass,
      allow_insecure   => true,
      download_options => $archive_options,
      cleanup          => false,
      require          => $rabbitmqadmin_archive_require,
    }

    file { '/usr/local/bin/rabbitmqadmin':
      owner   => 'root',
      group   => '0',
      source  => "${rabbitmq::rabbitmq_home}/rabbitmqadmin",
      mode    => '0755',
      require => $rabbitmqadmin_require,
    }
  }
}

class rabbitmq::install {

  $package_ensure   = $rabbitmq::package_ensure
  $package_name     = $rabbitmq::package_name
  $package_provider = $rabbitmq::package_provider
  $package_source   = $rabbitmq::package_source
  $manage_repo      = $rabbitmq::manage_repos

  if $manage_repo {
    Package['rabbitmq-server'] {
      require => Class['rabbitmq::repo::rhel'],
    }
  }

  if $package_provider == 'rpm' {
    package { 'rabbitmq-server':
      ensure   => $package_ensure,
      name     => $package_name,
      provider => $package_provider,
      source   => $package_source,
      notify   => Class['rabbitmq::service'],
    }
  }
  else {
    package { 'rabbitmq-server':
      ensure   => $package_ensure,
      name     => $package_name,
      provider => $package_provider,
      notify   => Class['rabbitmq::service'],
    }
  }
}

# @api private
#
# @summary 
#   Configure upstream RabbitMQ RPM repositories and locks packages versions if
#   necessary.
#
# @param rpm_repositories
#   Hash of RPM repositories to add to the system.
#
class rabbitmq::repo::rhel (
  Optional[Hash] $rpm_repositories = undef, # See Hiera
) {
  $rpm_repositories.each |String $repository, Hash $params| {
    yumrepo { $repository:
      name      => $params['name'],
      baseurl   => $params['baseurl'],
      gpgkey    => $params['gpgkey'],
      gpgcheck  => $params['gpgcheck'],
      sslcacert => $params['sslcacert'],
      sslverify => $params['sslverify'],
    }
  }

  case $rabbitmq::rabbitmq_version {
    '3.13': {
      $rabbitmq_pin_version = '3.13.*'
    }
    '3.12': {
      $rabbitmq_pin_version = '3.12.*'
    }
    '3.11': {
      $rabbitmq_pin_version = '3.11.*'
    }
    '3.10': {
      $rabbitmq_pin_version = '3.10.*'
    }
    '3.9': {
      $rabbitmq_pin_version = '3.9.*'
    }
    '3.8': {
      $rabbitmq_pin_version = '3.8.*'
    }
    '3.7': {
      $rabbitmq_pin_version = '3.7.*'
    }
    default: {
      $rabbitmq_pin_version = false
    }
  }

  $lock = $rabbitmq::package_yum_versionlock
  if $lock and $rabbitmq_pin_version {
    yum::versionlock { 'rabbitmq-server':
      version => $rabbitmq_pin_version,
    }
  }
}

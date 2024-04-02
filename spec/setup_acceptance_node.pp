case $facts['os']['family'] {
  'Debian': {
    $package_name = 'ssl-cert'
    $ssl_key_source = '/etc/ssl/private/ssl-cert-snakeoil.key'
    $ssl_cert_source = '/etc/ssl/certs/ssl-cert-snakeoil.pem'
  }
  'RedHat': {
    $package_name = 'mod_ssl'
    $ssl_key_source = '/etc/pki/tls/private/localhost.key'
    $ssl_cert_source = '/etc/pki/tls/certs/localhost.crt'
  }
}
if $facts['os']['family'] == 'RedHat' and versioncmp($facts['os']['release']['major'], '8') >= 0 {
  exec { 'gencerts':
    command     => '/usr/libexec/httpd-ssl-gencerts',
    refreshonly => true,
    subscribe   => Package[$package_name],
    before      => [
      File['/tmp/rabbitmq.key'],
      File['/tmp/rabbitmq.crt'],
    ],
  }
}

if $facts['os']['family'] == 'RedHat' {
  case $facts['os']['release']['major'] {
    '7': {
      package { 'epel-release':
        ensure => present,
      }
    }
    '8': {
      package { 'centos-release-rabbitmq-38':
        ensure => present,
      }
    }
    default: {
    }
  }
}

package { $package_name:
  ensure => installed,
}

file { '/tmp/rabbitmq.key':
  ensure => file,
  mode   => '0644',
  source => $ssl_key_source,
}
file { '/tmp/rabbitmq.crt':
  ensure => file,
  mode   => '0644',
  source => $ssl_cert_source,
}
file { '/tmp/cacert.crt':
  ensure => file,
  mode   => '0644',
  source => $ssl_cert_source,
}

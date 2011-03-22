# Define: rabbitmq::plugin
#
#   This defined resource type manages plugins for RabbitMQ
#
# Parameters:
#
# Actions:
#
# Requires:
#
# Sample Usage:
#
define rabbitmq::plugin(
  $ensure='UNSET',
  $source='UNSET'
) {

  $plugin_dir = $::rabbitmq::params::plugin_dir
  $service    = $::rabbitmq::params::service
  $packages   = $::rabbitmq::params::packages

  if $source == 'UNSET' {
    $source_real = "puppet:///modules/rabbitmq/plugins/${name}"
  } else {
    $source_real = $source
  }

  if $ensure == 'UNSET' {
    $ensure_real = 'present'
  } else {
    if $ensure in [ 'present', 'absent' ] {
      $ensure_real = $ensure
    } else {
      fail("ensure must be present or absent.  Received: ${ensure}")
    }
  }

  file { "${plugin_dir}/${name}":
    ensure  => $ensure_real,
    source  => $source_real,
    owner   => '0',
    group   => '0',
    mode    => '0644',
    require => Package[$packages],
    notify  => Service[$service],
  }

}

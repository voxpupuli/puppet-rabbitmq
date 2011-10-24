# Define: rabbitmq::plugin
#
#   This defined resource type manages plugins for RabbitMQ
#
#    NOTE: It is reommended to use packages to manage plugins if at all
#    possible.  There are packages for stomp and amqp available in the prosvc
#    repository at http://yum.puppetlabs.com/prosvc/
#
# Parameters:
#
# Actions:
#
# Requires:
#
# Sample Usage:
#
define rabbitmq::plugin( $ensure=present, $source='UNSET') {

  $plugin_dir = $::rabbitmq::server::plugin_dir

  if $source == 'UNSET' {
    $source_real = "puppet:///modules/rabbitmq/plugins/${name}"
  } else {
    validate_re($source, '^(/|puppet://)')
    $source_real = $source
  }

  validate_re($ensure, '^(present|absent)$')
  $ensure_real = $ensure

  file { "${plugin_dir}/${name}":
    ensure  => $ensure_real,
    source  => $source_real,
    owner   => '0',
    group   => '0',
    mode    => '0644',
    require => Class['rabbitmq'],
    notify  => Class['rabbitmq::service'],
  }

}

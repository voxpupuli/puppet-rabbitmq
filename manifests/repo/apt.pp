# @api private
#
# @summary
#   Configure upstream RabbitMQ APT repositories in DEB-822 format and pin
#   packages if necessary.
#
# @param key_id
#   ID of the key used to sign packages.
# @param key_server
#   Server used to retrieve the key used to sign packages.
# @param location
#   Array of URLs that host the packages.
# @param repos
#   Repositories components to enable.
#
class rabbitmq::repo::apt (
  String[1]        $key_id     = '0A9AF2115F4687BD29803A206B73A36E6026DFCA',
  String[1]        $key_server = 'keys.openpgp.org',
  Array[String[1]] $location   = ['localhost'], # OS dependent, it's in Hiera
  Array[String[1]] $repos      = ['main'],
) {
  # https://github.com/puppetlabs/puppetlabs-apt/issues/1184
  include apt

  # Uses legacy trusted.gpg, because apt::keyring does not de-armor the key
  apt::key { 'com.rabbitmq.team.gpg':
    id     => $key_id,
    server => $key_server,
  }

  apt::source { 'rabbitmq':
    source_format => 'sources',
    location      => $location,
    repos         => $repos,
    release       => [$facts['os']['distro']['codename']],
    types         => ['deb'],
    keyring       => '/etc/apt/trusted.gpg',
    comment       => 'Modern Erlang/OTP and RabbitMQ releases',
  }

  $pin    = $rabbitmq::package_apt_pin
  if $pin {
    # Determine the Erlang compatible with RabbitMQ one, otherwise dependencies
    # install fails
    # https://www.rabbitmq.com/docs/which-erlang
    case $rabbitmq::rabbitmq_version {
      '3.13': {
        $erlang_pin_version = '1:26.*'
        $rabbitmq_pin_version = '3.13.*'
      }
      '3.12': {
        $erlang_pin_version = '1:26.*'
        $rabbitmq_pin_version = '3.12.*'
      }
      '3.11': {
        $erlang_pin_version = '1:25.*'
        $rabbitmq_pin_version = '3.11.*'
      }
      '3.10': {
        $erlang_pin_version = '1:25.*'
        $rabbitmq_pin_version = '3.10.*'
      }
      '3.9': {
        $erlang_pin_version = '1:25.*'
        $rabbitmq_pin_version = '3.9.*'
      }
      '3.8': {
        $erlang_pin_version = '1:24.*'
        $rabbitmq_pin_version = '3.8.*'
      }
      '3.7': {
        $erlang_pin_version = '1:22.*'
        $rabbitmq_pin_version = '3.7.*'
      }
      default: {
        $erlang_pin_version = false
        $rabbitmq_pin_version = false
      }
    }

    if $rabbitmq_pin_version {
      apt::pin { 'rabbitmq':
        packages    => 'rabbitmq*',
        explanation => "Pin RabbitMQ packages to ${rabbitmq::rabbitmq_version}",
        priority    => $pin,
        version     => $rabbitmq_pin_version,
      }
    }

    if $erlang_pin_version {
      apt::pin { 'erlang':
        packages    => 'erlang*',
        explanation => "Pin Erlang packages to versions compatible with RabbitMQ ${rabbitmq::rabbitmq_version}",
        priority    => $pin,
        version     => $erlang_pin_version,
      }
    }
  }
}

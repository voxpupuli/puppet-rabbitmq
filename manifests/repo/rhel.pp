# Makes sure that the Packagecloud repo is installed
#
# @api private
class rabbitmq::repo::rhel (
  $location          = "https://packagecloud.io/rabbitmq/rabbitmq-server/el/${facts['os'][release][major]}/\$basearch",
  $erlang_location   = "https://packagecloud.io/rabbitmq/erlang/el/${facts['os'][release][major]}/\$basearch",
  String $key_source = $rabbitmq::package_gpg_key,
) {
  yumrepo { 'rabbitmq':
    ensure   => present,
    name     => 'rabbitmq_rabbitmq-server',
    baseurl  => $location,
    gpgkey   => $key_source,
    enabled  => 1,
    gpgcheck => 1,
  }

  # This is required because when using the latest version of rabbitmq because the latest version in EPEL
  # for Erlang is 22.0.7 which is not compatible: https://www.rabbitmq.com/which-erlang.html
  # yumrepo { 'erlang':
  #   ensure   => present,
  #   name     => 'rabbitmq_erlang',
  #   baseurl  => $erlang_location,
  #   gpgkey   => $key_source,
  #   enabled  => 1,
  #   gpgcheck => 1,
  # }

  # This may still be needed to prevent warnings
  # packagecloud key is gpg-pubkey-d59097ab-52d46e88
  exec { "rpm --import ${key_source}":
    path   => ['/bin','/usr/bin','/sbin','/usr/sbin'],
    unless => 'rpm -q gpg-pubkey-6026dfca-573adfde 2>/dev/null',
  }
}

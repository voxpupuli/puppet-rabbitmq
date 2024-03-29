# requires
#   puppetlabs-apt
#   puppetlabs-stdlib
#
# @api private
#
# @param location
# @param repos
# @param include_src
# @param key
# @param key_source
# @param key_content
# @param architecture
#
class rabbitmq::repo::apt (
  String[1] $location            = 'https://packagecloud.io/rabbitmq/rabbitmq-server',
  String[1] $repos               = 'main',
  Boolean $include_src           = false,
  String[1] $key                 = '8C695B0219AFDEB04A058ED8F4E789204D206F89',
  String[1] $key_source          = $rabbitmq::package_gpg_key,
  Optional[String[1]] $key_content  = $rabbitmq::key_content,
  Optional[String[1]] $architecture = undef,
) {
  $osname = downcase($facts['os']['name'])
  $pin    = $rabbitmq::package_apt_pin

  apt::source { 'rabbitmq':
    ensure       => present,
    location     => "${location}/${osname}",
    repos        => $repos,
    include      => { 'src' => $include_src },
    key          => {
      'id'      => $key,
      'source'  => $key_source,
      'content' => $key_content,
    },
    architecture => $architecture,
  }

  if $pin {
    apt::pin { 'rabbitmq':
      packages => '*',
      priority => $pin,
      origin   => inline_template('<%= require \'uri\'; URI(@location).host %>'),
    }
  }
}

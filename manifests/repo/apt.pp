# requires
#   puppetlabs-apt
#   puppetlabs-stdlib
#
# @api private
#
# @param repos
# @param include_src
# @param key
# @param key_source
# @param architecture
#
class rabbitmq::repo::apt (
  String[1] $repos               = 'main',
  Boolean $include_src           = false,
  String[1] $key                 = $rabbitmq::deb_repo_gpg_key,
  String[1] $key_source          = $rabbitmq::deb_repo_gpg_key_source,
  Optional[String[1]] $architecture = undef,
) {
  $osfamily = downcase($facts['os']['family'])
  $osname = downcase($facts['os']['name'])
  $pin    = $rabbitmq::package_apt_pin
  # https://www.rabbitmq.com/docs/install-debian
  apt::source { 'rabbitmq':
    ensure        => present,
    source_format => 'sources',
    location      => ["https://deb1.rabbitmq.com/rabbitmq-erlang/${osfamily}/${osname}", "https://deb2.rabbitmq.com/rabbitmq-erlang/${osfamily}/${osname}"],
    repos         => $repos,
    include       => { 'src' => $include_src },
    key           => {
      'id'      => $key,
      'source'  => $key_source,
      'keyring' => '/usr/share/keyrings/com.rabbitmq.team.gpg',
    },
    architecture  => $architecture,
  }

  if $pin {
    apt::pin { 'rabbitmq':
      packages => '*',
      priority => $pin,
      origin   => inline_template('<%= require \'uri\'; URI(@location).host %>'),
    }
  }
}

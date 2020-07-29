# requires
#   puppetlabs-apt
#   puppetlabs-stdlib
#
# @api private
class rabbitmq::repo::apt (
  String $location               = 'https://packagecloud.io/rabbitmq/rabbitmq-server',
  String $repos                  = 'main',
  Boolean $include_src           = false,
  String $key                    = '8C695B0219AFDEB04A058ED8F4E789204D206F89',
  String $key_source             = $rabbitmq::package_gpg_key,
  Optional[String] $key_content  = $rabbitmq::key_content,
  Optional[String] $architecture = undef,
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

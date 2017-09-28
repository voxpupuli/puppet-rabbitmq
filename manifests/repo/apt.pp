# requires
#   puppetlabs-apt
#   puppetlabs-stdlib
class rabbitmq::repo::apt(
  $location     = 'https://packagecloud.io/rabbitmq/rabbitmq-server',
  $repos        = 'main',
  $include_src  = false,
  $key          = '418A7F2FB0E1E6E7EABF6FE8C2E73424D59097AB',
  $key_source   = $rabbitmq::package_gpg_key,
  $key_content  = $rabbitmq::key_content,
  $architecture = undef,
  ) {

  $pin = $rabbitmq::package_apt_pin

  # ordering / ensure to get the last version of repository
  Class['rabbitmq::repo::apt']
  -> Class['apt::update']
  -> Package<| title == 'rabbitmq-server' |>

  $osname = downcase($facts['os']['name'])
  apt::source { 'rabbitmq':
    ensure       => present,
    location     => "${location}/${osname}",
    repos        => $repos,
    include      => { 'src' => $include_src },
    key          => {
      'id'      => $key,
      'source'  => $key_source,
      'content' =>  $key_content,
    },
    architecture => $architecture,
  }

  if $pin != '' {
    validate_re($pin, '\d{1,4}')
    apt::pin { 'rabbitmq':
      packages => '*',
      priority => $pin,
      origin   => 'packagecloud.io',
    }
  }
}

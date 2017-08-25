# requires
#   puppetlabs-apt
#   puppetlabs-stdlib
class rabbitmq::repo::apt(
  $location     = 'http://www.rabbitmq.com/debian/',
  $release      = 'testing',
  $repos        = 'main',
  $include_src  = false,
  $key          = '0A9AF2115F4687BD29803A206B73A36E6026DFCA',
  $key_source   = $rabbitmq::key_source,
  $key_content  = undef,
  $architecture = undef,
  ) {

  $pin = $rabbitmq::package_apt_pin

  # ordering / ensure to get the last version of repository
  Class['rabbitmq::repo::apt']
  -> Class['apt::update']
  -> Package<| title == 'rabbitmq-server' |>

  apt::source { 'rabbitmq':
    ensure       => present,
    location     => $location,
    release      => $release,
    repos        => $repos,
    include      => { 'src' => $include_src },
    key          => {
      'id'      => $key,
      'source'  => $key_source,
      'content' =>  $key_content
    },
    architecture => $architecture,
  }

  if $pin != '' {
    validate_re($pin, '\d{1,4}')
    apt::pin { 'rabbitmq':
      packages => '*',
      priority => $pin,
      origin   => 'www.rabbitmq.com',
    }
  }
}

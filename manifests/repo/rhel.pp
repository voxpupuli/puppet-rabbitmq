class rabbitmq::repo::rhel (
  $key = 'http://www.rabbitmq.com/rabbitmq-signing-key-public.asc',
) {

  Class['rabbitmq::repo::rhel'] -> Package<| title == 'rabbitmq-server' |>

  exec { "rpm --import ${key}":
    path   => ['/bin','/usr/bin','/sbin','/usr/sbin'],
    onlyif => 'test `rpm -qa | grep gpg-pubkey-056e8e56-468e43f2 | wc -l` -eq 0',
  }

}

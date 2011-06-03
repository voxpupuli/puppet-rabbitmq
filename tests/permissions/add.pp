rabbitmq_user { 'blah3':
  ensure => present,
  password => 'foo',
}
rabbitmq_vhost { 'foo':
  ensure => present,
}
rabbitmq_user_permissions { 'blah3/foo':
  ensure => present,
}

rabbitmq_user { 'blah7':
  ensure => present,
  password => 'foo',
}
rabbitmq_vhost { 'test5':
  ensure => present,
}
rabbitmq_user_permissions { 'blah7@test5':
  ensure => present,
  configure_permission => 'config2',
  read_permission => 'ready',
  #write_permission => 'ready',
}

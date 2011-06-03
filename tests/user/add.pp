rabbitmq_user { 'blah2':
  ensure => present,
  password => 'phoey!',
  provider => 'rabbitmqctl',
}

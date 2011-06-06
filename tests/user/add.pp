rabbitmq_user { ['blah2', 'blah3', 'blah4']:
  ensure => present,
  password => 'phoey!',
 # provider => 'rabbitmqctl',
}

class { 'rabbitmq::repo::apt': 
  pin => '900',
}->
class { 'rabbitmq::server':
  delete_guest_user => true,
#  version           => '2.4.1',
}->
rabbitmq_user { 'dan':
  password  => 'pass',
  tags      => [ 'administrator', 'dantheman' ],
  provider  => 'rabbitmqctl',
}->
rabbitmq_vhost { 'myhost': 
  provider => 'rabbitmqctl',
}
rabbitmq_user_permissions { 'dan@myhost':
  configure_permission => '.*',
  read_permission      => '.*',
  write_permission     => '.*',
  provider => 'rabbitmqctl',
}

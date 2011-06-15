class { 'rabbitmq':
  port => '5672',
  delete_guest_user => true,
  version => 'latest',
}

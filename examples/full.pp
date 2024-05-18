class { 'rabbitmq':
  delete_guest_user => true,
  package_apt_pin   => 900,
}

-> rabbitmq_user { 'dan':
  admin    => true,
  password => 'pass',
  provider => 'rabbitmqctl',
}

-> rabbitmq_vhost { 'myhost':
  provider => 'rabbitmqctl',
}

rabbitmq_user_permissions { 'dan@myhost':
  configure_permission => '.*',
  read_permission      => '.*',
  write_permission     => '.*',
  provider             => 'rabbitmqctl',
}

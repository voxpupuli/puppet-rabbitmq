class { 'rabbitmq::repo::apt': }
class { 'rabbitmq':
  delete_guest_user => true
}


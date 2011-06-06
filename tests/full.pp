# this shows how to install and configure the latest version of 
# rabbitmq from their repo
# TODO - I may need to pin the repo
class { 'rabbitmq::repo::apt': 
  pin => '900',
}
class { 'rabbitmq':
  delete_guest_user => true,
  require           => Class['rabbitmq::repo::apt'],
#  version           => '2.4.1',
}


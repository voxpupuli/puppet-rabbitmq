$rabbitmq_plugins = [ 'amqp_client-2.3.1.ez', 'rabbit_stomp-2.3.1.ez' ] 
class { 'rabbitmq::server':
  install_stomp => true,
}

rabbitmq::plugin { $rabbitmq_plugins:
  ensure => present,
  require => Class['rabbitmq']
}

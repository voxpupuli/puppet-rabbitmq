$rabbitmq_plugins = ['amqp_client', 'rabbitmq_stomp']

class { 'rabbitmq':
  config_stomp => true,
}

rabbitmq_plugin { $rabbitmq_plugins:
  ensure   => present,
  require  => Class['rabbitmq'],
  provider => 'rabbitmqplugins',
}

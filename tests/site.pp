node default {

  $rabbitmq_plugins = [ 'amqp_client-2.3.1.ez', 'rabbit_stomp-2.3.1.ez' ]

  class { 'rabbitmq::server':
    config => '[ {rabbit_stomp, [{tcp_listeners, [1234]} ]} ].',
  }

  # Required for MCollective
  rabbitmq::plugin { $rabbitmq_plugins:
    ensure => present,
  }

}


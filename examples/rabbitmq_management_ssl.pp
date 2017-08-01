
node 'rabbit.example.com' {

class { 'rabbitmq':
  service_manage        => false,
  heartbeat             => '0',
  port                  => '15671',
  delete_guest_user     => false,
  ssl                   => true,
  ssl_management_port   => '15672',
  management_ssl        => true,
  ssl_only              => true,
  ssl_cacert            => '/etc/rabbitmq/ssl/ca.crt',
  ssl_cert              => '/etc/rabbitmq/ssl/rabbit.example.com.crt',
  ssl_key               => '/etc/rabbitmq/ssl/rabbit.example.com.key',
  ssl_versions          => ['tlsv1.2', 'tlsv1.1'],
  environment_variables => {
    'NODENAME'    => 'rabbit',
    'SERVICENAME' => 'Rabbit',
    'CONFIG_FILE' =>  '/etc/rabbitmq/rabbitmq'
  }

}

rabbitmq_plugin {'rabbitmq_management':
  ensure => present,
}

rabbitmq_user { 'admin':
  admin    => true,
  password => 'change_password',
}

}

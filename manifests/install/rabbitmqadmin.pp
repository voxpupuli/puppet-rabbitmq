class rabbitmq::install::rabbitmqadmin {

  $management_port = $rabbitmq::management_port

  exec { 'Download rabbitmqadmin':
    command => "curl http://localhost:${management_port}/cli/rabbitmqadmin -o /var/lib/rabbitmq/rabbitmqadmin",
    path    => '/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin',
    creates => '/var/lib/rabbitmq/rabbitmqadmin',
    require => [
      Class['rabbitmq::service'],
      Rabbitmq_plugin['rabbitmq_management']
    ],
  }

  file { '/usr/local/bin/rabbitmqadmin':
    owner   => 'root',
    group   => 'root',
    source  => '/var/lib/rabbitmq/rabbitmqadmin',
    mode    => '0755',
    require => Exec['Download rabbitmqadmin'],
  }

}

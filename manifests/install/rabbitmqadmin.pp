class rabbitmq::install::rabbitmqadmin {

  $management_port = $rabbitmq::management_port

  $rabbitmqadmin_url  = "http://localhost:${management_port}/cli/rabbitmqadmin"
  $rabbitmqadmin_path = "/var/lib/rabbitmq/rabbitmqadmin"
  exec { 'Download rabbitmqadmin':
    command => "bash -c 'curl ${rabbitmqadmin_url} -o ${rabbitmqadmin_path} || wget ${rabbitmqadmin_url} -O ${rabbitmqadmin_path}'",
    path    => '/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin',
    creates => $rabbitmqadmin_path,
    require => [
      Class['rabbitmq::service'],
      Rabbitmq_plugin['rabbitmq_management']
    ],
  }

  file { '/usr/local/bin/rabbitmqadmin':
    owner   => 'root',
    group   => 'root',
    source  => $rabbitmqadmin_path,
    mode    => '0755',
    require => Exec['Download rabbitmqadmin'],
  }

}

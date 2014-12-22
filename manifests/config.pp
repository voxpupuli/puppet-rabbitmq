# Class: rabbitmq::config
# Sets all the configuration values for RabbitMQ and creates the directories for
# config and ssl.
class rabbitmq::config {

  $admin_enable               = $rabbitmq::admin_enable
  $cluster_node_type          = $rabbitmq::cluster_node_type
  $cluster_nodes              = $rabbitmq::cluster_nodes
  $config                     = $rabbitmq::config
  $config_cluster             = $rabbitmq::config_cluster
  $config_path                = $rabbitmq::config_path
  $config_stomp               = $rabbitmq::config_stomp
  $default_user               = $rabbitmq::default_user
  $default_pass               = $rabbitmq::default_pass
  $env_config                 = $rabbitmq::env_config
  $env_config_path            = $rabbitmq::env_config_path
  $erlang_cookie              = $rabbitmq::erlang_cookie
  $management_port            = $rabbitmq::management_port
  $node_ip_address            = $rabbitmq::node_ip_address
  $plugin_dir                 = $rabbitmq::plugin_dir
  $port                       = $rabbitmq::port
  $tcp_keepalive              = $rabbitmq::tcp_keepalive
  $service_name               = $rabbitmq::service_name
  $ssl                        = $rabbitmq::ssl
  $ssl_only                   = $rabbitmq::ssl_only
  $ssl_cacert                 = $rabbitmq::ssl_cacert
  $ssl_cert                   = $rabbitmq::ssl_cert
  $ssl_key                    = $rabbitmq::ssl_key
  $ssl_port                   = $rabbitmq::ssl_port
  $ssl_management_port        = $rabbitmq::ssl_management_port
  $ssl_stomp_port             = $rabbitmq::ssl_stomp_port
  $ssl_verify                 = $rabbitmq::ssl_verify
  $ssl_fail_if_no_peer_cert   = $rabbitmq::ssl_fail_if_no_peer_cert
  $stomp_port                 = $rabbitmq::stomp_port
  $wipe_db_on_cookie_change   = $rabbitmq::wipe_db_on_cookie_change
  $config_variables           = $rabbitmq::config_variables
  $config_kernel_variables    = $rabbitmq::config_kernel_variables
  $cluster_partition_handling = $rabbitmq::cluster_partition_handling
  $default_env_variables      =  {
    'RABBITMQ_NODE_PORT'        => $port,
    'RABBITMQ_NODE_IP_ADDRESS'  => $node_ip_address
  }

  # Handle env variables.
  $environment_variables = merge($default_env_variables, $rabbitmq::environment_variables)

  file { '/etc/rabbitmq':
    ensure => directory,
    owner  => '0',
    group  => '0',
    mode   => '0644',
  }

  file { '/etc/rabbitmq/ssl':
    ensure => directory,
    owner  => '0',
    group  => '0',
    mode   => '0644',
  }

  file { 'rabbitmq.config':
    ensure  => file,
    path    => $config_path,
    content => template($config),
    owner   => '0',
    group   => '0',
    mode    => '0644',
    notify  => Class['rabbitmq::service'],
  }

  file { 'rabbitmq-env.config':
    ensure  => file,
    path    => $env_config_path,
    content => template($env_config),
    owner   => '0',
    group   => '0',
    mode    => '0644',
    notify  => Class['rabbitmq::service'],
  }

  file { 'rabbitmqadmin.conf':
    ensure  => file,
    path    => '/etc/rabbitmq/rabbitmqadmin.conf',
    content => template('rabbitmq/rabbitmqadmin.conf.erb'),
    owner   => '0',
    group   => '0',
    mode    => '0644',
    require => File['/etc/rabbitmq'],
  }

  if $config_cluster {

    if $erlang_cookie == undef {
      fail('You must set the $erlang_cookie value in order to configure clustering.')
    } else {
      rabbitmq_erlang_cookie { '/var/lib/rabbitmq/.erlang.cookie':
        content      => $erlang_cookie,
        force        => $wipe_db_on_cookie_change,
        service_name => $service_name,
        before       => File['rabbitmq.config'],
        notify       => Class['rabbitmq::service'],
      }
    }
  }


}


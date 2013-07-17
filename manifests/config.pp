#
class rabbitmq::config(
  $cluster_disk_nodes       = $rabbitmq::cluster_disk_nodes,
  $cluster_node_type        = $rabbitmq::cluster_node_type,
  $cluster_nodes            = $rabbitmq::cluster_nodes,
  $cluster_nodes_real       = $rabbitmq::cluster_nodes_real,
  $config                   = $rabbitmq::config,
  $config_cluster           = $rabbitmq::config_cluster,
  $config_path              = $rabbitmq::config_path,
  $config_mirrored_queues   = $rabbitmq::config_mirrored_queues,
  $config_stomp             = $rabbitmq::config_stomp,
  $delete_guest_user        = $rabbitmq::delete_guest_user,
  $env_config               = $rabbitmq::env_config,
  $env_config_path          = $rabbitmq::env_config_path,
  $erlang_cookie            = $rabbitmq::erlang_cookie,
  $node_ip_address          = $rabbitmq::node_ip_address,
  $plugin_dir               = $rabbitmq::plugin_dir,
  $port                     = $rabbitmq::port,
  $service_name             = $rabbitmq::service_name,
  $stomp_port               = $rabbitmq::stomp_port,
  $wipe_db_on_cookie_change = $rabbitmq::wipe_db_on_cookie_change,
) inherits rabbitmq {

  file { '/etc/rabbitmq':
    ensure  => directory,
    owner   => '0',
    group   => '0',
    mode    => '0644',
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

  if $delete_guest_user {
    # delete the default guest user
    rabbitmq_user{ 'guest':
      ensure   => absent,
      provider => 'rabbitmqctl',
    }
  }

  if $config_cluster {

    # rabbitmq_erlang_cookie is a fact in this module.
    if $erlang_cookie != $::rabbitmq_erlang_cookie {
      # Safety check.
      if $wipe_db_on_cookie_change {
        exec { 'wipe_db':
          command    => "puppet resource service ${service_name} ensure=stopped; rm -rf /var/lib/rabbitmq/mnesia",
          path       => '/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin',
        }
      } else {
        fail("ERROR: The current erlang cookie is ${::rabbitmq_erlang_cookie} and needs to change to ${erlang_cookie}. In order to do this the RabbitMQ database needs to be wiped.  Please set the parameter called wipe_db_on_cookie_change to true to allow this to happen automatically.")
      }
    }

    file { 'erlang_cookie':
      ensure  => 'present',
      path    => '/var/lib/rabbitmq/.erlang.cookie',
      owner   => 'rabbitmq',
      group   => 'rabbitmq',
      mode    => '0400',
      content => $erlang_cookie,
      replace => true,
      before  => File['rabbitmq.config'],
      require => Exec['wipe_db'],
      notify  => Class['rabbitmq::service'],
    }
  }


}

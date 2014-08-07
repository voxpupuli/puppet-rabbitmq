#
class rabbitmq::management {

  $delete_guest_user = $rabbitmq::delete_guest_user

  if $delete_guest_user {
    rabbitmq_user{ 'guest':
      ensure   => absent,
      provider => 'rabbitmqctl',
    }
  }

  if $rabbitmq::config_mirrored_queues {
    rabbitmq::policy { 'HA':
    pattern    => '^(?!amq\.).*',
    vhost      => '/',
    definition => '{"ha-mode":"exactly","ha-params":2,"ha-sync-mode":"automatic"}'
    }
    rabbitmq::policy { 'HA2':
    pattern    => '^(?!amq\.).*',
    vhost      => $rabbitmq::vhost,
    definition => '{"ha-mode":"exactly","ha-params":2,"ha-sync-mode":"automatic"}'
    }
  }
}

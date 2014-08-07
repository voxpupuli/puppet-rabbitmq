define rabbitmq::policy (
    $pattern,
    $definition,
    $vhost    = '/',
    $priority = '--priority 1',
    $apply_to = '--apply-to queues',
    $policy_name = 'HA',
){
  exec { "rabbitmq policy: ${title}":
    command     => "rabbitmqctl -p '${vhost}' 'set_policy' '${policy_name}' '${pattern}' '${definition}' '${priority}' '${apply_to}'",
    unless      => "rabbitmqctl list_policies -p '$vhost' | grep '^${vhost}'",
    path        => ['/bin','/sbin','/usr/bin','/usr/sbin'],
    require     => Class['rabbitmq::service'],
  }
}

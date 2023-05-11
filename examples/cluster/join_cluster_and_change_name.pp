# This sets the cluster name to `test_cluster`
# If run on another host than host1, this will join the host1's cluster
rabbitmq_cluster { 'test_cluster':
  init_node => 'host1',
}

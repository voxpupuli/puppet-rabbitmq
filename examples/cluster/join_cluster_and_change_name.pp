rabbitmq_cluster { 'test_cluster':
  init_node => 'host1',
}
# This will join host2 to host1s cluster and set the cluster name to test_cluster

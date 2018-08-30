Facter.add(:rabbitmq_clustername) do
  setcode do
    if Facter::Util::Resolution.which('rabbitmqctl')
      rabbitmq_clustername = Facter::Core::Execution.execute('rabbitmqctl cluster_status 2>&1')
      %r{^ {cluster_name,<<"(.*)">>},}.match(rabbitmq_clustername)[1]
    end
  end
end

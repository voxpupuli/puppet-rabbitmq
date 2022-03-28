# frozen_string_literal: true

Facter.add(:rabbitmq_clustername) do
  setcode do
    if Facter::Util::Resolution.which('rabbitmqctl')
      ret = nil
      cluster_status = Facter::Core::Execution.execute('rabbitmqctl -q cluster_status 2>&1')
      [%r!{cluster_name,<<"(\S+)">>}!, %r{^Cluster name: (\S+)$}].each do |r|
        if (data = r.match(cluster_status))
          ret = data[1]
          break
        end
      end
    end
    ret
  end
end

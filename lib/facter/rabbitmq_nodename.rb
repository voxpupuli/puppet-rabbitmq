Facter.add(:rabbitmq_nodename) do
  setcode do
    if Facter::Util::Resolution.which('rabbitmqctl')
      rabbitmq_nodename = Facter::Core::Execution.execute('rabbitmqctl status 2>&1')
      begin
        %r{^Status of node '?([\w\.\-]+@[\w\.\-]+)'?}.match(rabbitmq_nodename)[1]
      rescue
        Facter.debug("Error: rabbitmq_nodename facter failed. Output was #{rabbitmq_nodename}")
      end
    end
  end
end

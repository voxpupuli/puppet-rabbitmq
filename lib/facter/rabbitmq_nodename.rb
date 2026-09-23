# frozen_string_literal: true

Facter.add(:rabbitmq_nodename) do
  confine { Facter::Core::Execution.which('rabbitmqctl') }
  setcode do
    rabbitmq_nodename = Facter::Core::Execution.execute('rabbitmqctl status 2>&1')
    begin
      %r{^Status of node '?([\w.-]+@[\w.-]+)'?}.match(rabbitmq_nodename)[1]
    rescue StandardError
      Facter.debug("Error: rabbitmq_nodename facter failed. Output was #{rabbitmq_nodename}")
    end
  end
end

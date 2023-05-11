# frozen_string_literal: true

Facter.add(:rabbitmq_version) do
  setcode do
    if Facter::Util::Resolution.which('rabbitmqadmin')
      rabbitmq_version = Facter::Core::Execution.execute('rabbitmqadmin --version 2>&1')
      %r{^rabbitmqadmin ([\w.]+)}.match(rabbitmq_version).to_a[1]
    end
  end
end

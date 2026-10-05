# frozen_string_literal: true

Facter.add(:rabbitmq_version) do
  confine do
    Facter::Core::Execution.which('rabbitmq-diagnostics')
  end
  setcode do
    rabbitmq_version = Facter::Core::Execution.execute('rabbitmq-diagnostics version 2>&1')
    # Return nil if it's not a valid version number for compatibility with old fact behaviour
    rabbitmq_version.match?(%r{\A[\d.]+\z}) ? rabbitmq_version : nil
  end
end

# frozen_string_literal: true

Facter.add(:rabbitmq_plugins_dirs) do
  setcode do
    if Facter::Util::Resolution.which('rabbitmqctl')
      rabbitmq_pluginsdirs_env = Facter::Core::Execution.execute("rabbitmqctl eval 'application:get_env(rabbit, plugins_dir).'")
      rabbitmq_plugins_dirs_match = %r{^\{ok,"(/.+/\w+)}.match(rabbitmq_pluginsdirs_env)
      rabbitmq_plugins_dirs_match[1].split(':') if rabbitmq_plugins_dirs_match
    end
  end
end

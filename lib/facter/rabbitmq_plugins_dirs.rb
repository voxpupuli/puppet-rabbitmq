Facter.add(:rabbitmq_plugins_dirs) do
  setcode do
    if Facter::Util::Resolution.which('rabbitmqctl')
      rabbitmq_pluginsdirs_env = Facter::Core::Execution.execute("rabbitmqctl eval 'application:get_env(rabbit, plugins_dir).'")
      rabbitmq_plugins_dirs = %r{^\{ok\,\"(\/.+\/\w+)}.match(rabbitmq_pluginsdirs_env)[1]
      rabbitmq_plugins_dirs.split(':')
    end
  end
end

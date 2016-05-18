require 'puppet'
require 'set'

# Backware compatibility with Puppet 2
# Source: https://github.com/puppetlabs/puppet/blob/master/lib/puppet/util.rb
def internal_merge_environment(env_hash, mode = default_env)
  case mode
    when :posix
      env_hash.each { |name, val| ENV[name.to_s] = val }
    when :windows
      env_hash.each do |name, val|
        Puppet::Util::Windows::Process.set_environment_variable(name.to_s, val)
      end
    else
      raise "Unable to merge given values into the current environment for mode #{mode}"
  end
end

# Backware compatibility with Puppet 2
# Source: https://github.com/puppetlabs/puppet/blob/master/lib/puppet/util.rb
def internal_clear_environment(mode = default_env)
  case mode
    when :posix
      ENV.clear
    when :windows
      Puppet::Util::Windows::Process.get_environment_strings.each do |key, _|
        Puppet::Util::Windows::Process.set_environment_variable(key, nil)
      end
    else
      raise "Unable to clear the environment for mode #{mode}"
  end
end

# Backware compatibility with Puppet 2
# Source: https://github.com/puppetlabs/puppet/blob/master/lib/puppet/util.rb
def internal_get_environment(mode = default_env)
  case mode
    when :posix
      ENV.to_hash
    when :windows
      Puppet::Util::Windows::Process.get_environment_strings
    else
      raise "Unable to retrieve the environment for mode #{mode}"
  end
end

# Backware compatibility with Puppet 2
# Source: https://github.com/puppetlabs/puppet/blob/master/lib/puppet/util.rb
def internal_withenv(hash, mode = :posix)
  saved = internal_get_environment(mode)
  internal_merge_environment(hash, mode)
  yield
ensure
  if saved
    internal_clear_environment(mode)
    internal_merge_environment(saved, mode)
  end
end

Puppet::Type.type(:rabbitmq_erlang_cookie).provide(:ruby) do

  env_path = '/opt/puppetlabs/bin:/usr/local/bin:/usr/bin:/bin'

  if Puppet::PUPPETVERSION.to_f < 3
    puppet_path = internal_withenv(:PATH => env_path) do
      Puppet::Util.which('puppet')
    end
  else
    puppet_path = Puppet::Util.withenv(:PATH => env_path) do
      Puppet::Util.which('puppet')
    end
  end

  defaultfor :feature => :posix

  confine :false => puppet_path.nil?
  if Puppet::PUPPETVERSION.to_f < 3
    if !puppet_path.nil?
      commands :puppet => puppet_path
    end
  else
    has_command(:puppet, puppet_path) unless puppet_path.nil?
  end

  def exists?
    # Hack to prevent the create method from being called.
    # We never need to create or destroy this resource, only change its value
    true
  end

  def content=(value)
    if resource[:force] == :true # Danger!
      puppet('resource', 'service', resource[:service_name], 'ensure=stopped')
      FileUtils.rm_rf(resource[:rabbitmq_home] + File::SEPARATOR + 'mnesia')
      File.open(resource[:path], 'w') do |cookie|
        cookie.chmod(0400)
        cookie.write(value)
      end
      FileUtils.chown(resource[:rabbitmq_user], resource[:rabbitmq_group], resource[:path])
    else
      fail("The current erlang cookie needs to change. In order to do this the RabbitMQ database needs to be wiped.  Please set force => true to allow this to happen automatically.")
    end
  end

  def content
    if File.exists?(resource[:path])
      File.read(resource[:path])
    else
      ''
    end
  end

end

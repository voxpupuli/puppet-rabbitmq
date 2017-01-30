require "rabbitmq/http/client"

$endpoint = "http://localhost:15672"
$client = RabbitMQ::HTTP::Client.new($endpoint, :username => "guest", :password => "guest")

Puppet::Type.type(:rabbitmq_user_permissions).provide(:rabbitmqhttp, :parent => Puppet::Type.type(:rabbitmq_user_permissions).provider(:rabbitmqctl)) do

  defaultfor :feature=> :posix

  # cache users permissions
  def self.users(name, vhost)
    @users = {} unless @users
    unless @users[name]
      @users[name] = {}
      @users[name][vhost] = {}
      user_perm = $client.list_permissions
      user_perm.each do |line|
        if line.user.eql? name
          @users[line.user][line.vhost] =
            {:configure => line.configure, :read => line.read, :write => line.write}
        end
      end
    end
    @users[name][vhost]
  end

  def users(name, vhost)
    self.class.users(name, vhost)
  end

  def should_user
    if @should_user
      @should_user
    else
      @should_user = resource[:name].split('@')[0]
    end
  end

  def should_vhost
    if @should_vhost
      @should_vhost
    else
      @should_vhost = resource[:name].split('@')[1]
    end
  end

  def create
    resource[:configure_permission] ||= "''"
    resource[:read_permission]      ||= "''"
    resource[:write_permission]     ||= "''"
    $client.update_permissions_of(should_vhost, should_user, :write => resource[:write_permission], :read => resource[:read_permission], :configure => resource[:configure_permission])
    #rabbitmqctl('set_permissions', '-p', should_vhost, should_user, resource[:configure_permission], resource[:write_permission], resource[:read_permission])
  end

  def destroy
    $client.clear_permissions_of(should_vhost, should_user)
    #rabbitmqctl('clear_permissions', '-p', should_vhost, should_user)
  end

  # I am implementing prefetching in exists b/c I need to be sure
  # that the rabbitmq package is installed before I make this call.
  def exists?
    users(should_user, should_vhost)
  end

  def configure_permission
    users(should_user, should_vhost)[:configure]
  end

  def configure_permission=(perm)
    set_permissions
  end

  def read_permission
    users(should_user, should_vhost)[:read]
  end

  def read_permission=(perm)
    set_permissions
  end

  def write_permission
    users(should_user, should_vhost)[:write]
  end

  def write_permission=(perm)
    set_permissions
  end

  # implement memoization so that we only call set_permissions once
  def set_permissions
    unless @permissions_set
      @permissions_set = true
      resource[:configure_permission] ||= configure_permission
      resource[:read_permission]      ||= read_permission
      resource[:write_permission]     ||= write_permission
      rabbitmqctl('set_permissions', '-p', should_vhost, should_user,
        resource[:configure_permission], resource[:write_permission],
        resource[:read_permission]
      )
    end
  end

  def self.strip_backslashes(string)
    # See: https://github.com/rabbitmq/rabbitmq-server/blob/v1_7/docs/rabbitmqctl.1.pod#output-escaping
    string.gsub(/\\\\/, '\\')
  end

end

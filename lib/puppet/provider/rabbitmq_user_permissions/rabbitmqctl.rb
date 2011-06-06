Puppet::Type.type(:rabbitmq_user_permissions).provide(:rabbitmqctl) do

  commands :rabbitmqctl => 'rabbitmqctl'

  def create 
    rabbitmqctl('set_permissions', '-p', @should_vhost, @should_user, resource[:configure_permission], resource[:read_permission], resource[:write_permission]) 
  end

  def destroy
    rabbitmqctl('clear_permissions', '-p', @should_vhost, @should_user) 
  end
 
  # exists is always created before create/destroy
  def exists?
    @should_user, @should_vhost = resource[:name].split('@')
    out = rabbitmqctl('list_user_permissions', @should_user).split(/\n/)[1..-2].detect do |x|
      x.match(/^#{@should_vhost}\s+\S+\s+\S+\s+\S+$/)
    end
  end

end

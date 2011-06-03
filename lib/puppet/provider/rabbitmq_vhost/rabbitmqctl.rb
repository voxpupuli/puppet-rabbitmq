Puppet::Type.type(:rabbitmq_vhost).provide(:rabbitmqctl) do

  commands :rabbitmqctl => 'rabbitmqctl'

  def create 
    rabbitmqctl('add_vhost', resource[:name]) 
  end

  def destroy
    rabbitmqctl('delete_vhost', resource[:name]) 
  end
 
  def exists?
    out = rabbitmqctl('list_vhosts').split(/\n/)[1..-2].detect do |x|
      x.match(/^#{resource[:name]}$/)
    end
  end

end

require 'puppet'
Puppet::Type.type(:rabbitmq_user).provide(:rabbitmqctl) do

  commands :rabbitmqctl => 'rabbitmqctl'

  def create
    raise ArgumentError, 'must set password when creating user' unless resource[:password]
    rabbitmqctl('add_user', resource[:name], resource[:password]) 
  end

  def destroy
    rabbitmqctl('delete_user', resource[:name]) 
  end
 
  def exists?
    out = rabbitmqctl('list_users').split(/\n/)[1..-2].detect do |x|
      x.match(/^#{resource[:name]}(\s+\S+|)$/)
    end
  end

end

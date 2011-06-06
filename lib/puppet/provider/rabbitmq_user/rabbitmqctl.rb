require 'puppet'
Puppet::Type.type(:rabbitmq_user).provide(:rabbitmqctl) do

  commands :rabbitmqctl => 'rabbitmqctl'
  defaultfor :kernel => :Linux

  def self.instances
    rabbitmqctl('list_users').split(/\n/)[1..-2].collect do |line|
      if line =~ /^(\S+)(\s+\S+|)$/
        new(:name => $1)
      else
        raise Puppet::Error, "Cannot parse invalid user line: #{line}"
      end
    end
  end

  def create
    raise ArgumentError, 'must set password when creating user' unless resource[:password]
    rabbitmqctl('add_user', resource[:name], resource[:password]) 
  end

  def destroy
    rabbitmqctl('delete_user', resource[:name]) 
  end
 
  def exists?
    out = rabbitmqctl('list_users').split(/\n/)[1..-2].detect do |line|
      line.match(/^#{resource[:name]}(\s+\S+|)$/)
    end
  end

  # def password
  # def password=()

end

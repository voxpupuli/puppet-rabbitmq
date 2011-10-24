require 'puppet'
Puppet::Type.type(:rabbitmq_user).provide(:rabbitmqctl) do

  commands :rabbitmqctl => 'rabbitmqctl'
  defaultfor :feature => :posix

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
    rabbitmqctl('add_user', resource[:name], resource[:password])
    if resource[:admin] == :true
      make_user_admin()
    end
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
  def admin
    match = rabbitmqctl('list_users').split(/\n/)[1..-2].collect do |line|
      line.match(/^#{resource[:name]}\s+\[(administrator)?\]/)
    end.compact.first
    if match
      (:true if match[1].to_s == 'administrator') || :false
    else
      raise Puppet::Error, "Could not match line '#{resource[:name]} [(administrator)?]' from list_users. This could indicate that you are using a version of rabbitmq older than 2.6.1 or that you have set tags for this user other than administrator."
    end
  end

  def admin=(state)
    if state == :true
      make_user_admin()
    else
      rabbitmqctl('set_user_tags', resource[:name])
    end
  end

  def make_user_admin
    rabbitmqctl('set_user_tags', resource[:name], 'administrator')
  end

end

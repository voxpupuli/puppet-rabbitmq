require 'puppet'
require 'set'
Puppet::Type.type(:rabbitmq_user).provide(:rabbitmqctl) do

  if Puppet::PUPPETVERSION.to_f < 3
    commands :rabbitmqctl => 'rabbitmqctl'
  else
     has_command(:rabbitmqctl, 'rabbitmqctl') do
       environment :HOME => "/tmp"
     end
  end

  defaultfor :feature => :posix

  def self.instances
    rabbitmqctl('-q', 'list_users').split(/\n/).collect do |line|
      if line =~ /^(\S+)(\s+\[.*?\]|)$/
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
    if !resource[:tags].nil?
      set_user_tags(resource[:tags])
    end
  end

  def change_password
    rabbitmqctl('change_password', resource[:name], resource[:password])
  end

  def password
    nil
  end


  def check_password
    response = rabbitmqctl('eval', 'rabbit_auth_backend_internal:check_user_login(<<"' + resource[:name] + '">>, [{password, <<"' + resource[:password] +'">>}]).')
    if response.include? 'invalid credentials'
        false
    else
        true
    end
  end

  def destroy
    rabbitmqctl('delete_user', resource[:name])
  end

  def exists?
    rabbitmqctl('-q', 'list_users').split(/\n/).detect do |line|
      line.match(/^#{Regexp.escape(resource[:name])}(\s+(\[.*?\]|\S+)|)$/)
    end
  end

 
  def tags
    get_user_tags.entries.sort
  end


  def tags=(tags)
    if ! tags.nil?
      set_user_tags(tags)
    end
  end

  def admin
    if usertags = get_user_tags
      (:true if usertags.include?('administrator')) || :false
    else
      raise Puppet::Error, "Could not match line '#{resource[:name]} (true|false)' from list_users (perhaps you are running on an older version of rabbitmq that does not support admin users?)"
    end
  end

  def admin=(state)
    if state == :true
      make_user_admin()
    else
      usertags = get_user_tags
      usertags.delete('administrator')
      rabbitmqctl('set_user_tags', resource[:name], usertags.entries.sort)
    end
  end

  def set_user_tags(tags)
    is_admin = get_user_tags().member?("administrator") \
               || resource[:admin] == :true
    usertags = Set.new(tags)
    if is_admin
      usertags.add("administrator")
    end
    rabbitmqctl('set_user_tags', resource[:name], usertags.entries.sort)
  end

  def make_user_admin
    usertags = get_user_tags
    usertags.add('administrator')
    rabbitmqctl('set_user_tags', resource[:name], usertags.entries.sort)
  end

  private
  def get_user_tags
    match = rabbitmqctl('-q', 'list_users').split(/\n/).collect do |line|
      line.match(/^#{Regexp.escape(resource[:name])}\s+\[(.*?)\]/)
    end.compact.first
    Set.new(match[1].split(/, /)) if match
  end
end

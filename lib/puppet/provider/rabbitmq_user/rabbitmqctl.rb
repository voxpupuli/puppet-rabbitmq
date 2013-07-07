require 'puppet'
Puppet::Type.type(:rabbitmq_user).provide(:rabbitmqctl) do

  commands :rabbitmqctl => 'rabbitmqctl'
  defaultfor :feature => :posix

  def self.instances
    rabbitmqctl('list_users').split(/\n/)[1..-2].collect do |line|
      if line =~ /^(\S+)(\s+\[.*\]|)$/
        new(:name => $1)
      else
        raise Puppet::Error, "Cannot parse invalid user line: #{line}"
      end
    end
  end

  def create
    rabbitmqctl('add_user', resource[:name], resource[:password])
    if resource[:admin] == :true or not user_tags_get().empty?
      set_user_tags()
    end
  end

  def destroy
    rabbitmqctl('delete_user', resource[:name])
  end

  def exists?
    out = rabbitmqctl('list_users').split(/\n/)[1..-2].detect do |line|
      line.match(/^#{Regexp.escape(resource[:name])}(\s+\[.*\]|)$/)
    end
  end

  # def password
  # def password=()
  def admin
    match = rabbitmqctl('list_users').split(/\n/)[1..-2].collect do |line|
      line.match(/^#{Regexp.escape(resource[:name])}\s+\[(.*)\]/)
    end.compact.first
    if match
      if match[1].to_s.split(/,\s*/).index('administrator')
        unless resource[:admin]==:false and user_tags_get().index("administrator")
          :true 
        else
          # admin and user_tags can conflict if admin is unset but the user 
          # tags include administrator.  This confuses puppet.  So don't report
          # the administrator tag in this case even though present
          :false
        end
      else 
        # really not found
        :false
      end
    else
      raise Puppet::Error, "Could not match line '#{resource[:name]} (true|false)' from list_users (perhaps you are running on an older version of rabbitmq that does not support admin users?)"
    end
  end

  def admin=(state)
    set_user_tags()
  end

  def user_tags_get
    # there is probaby a better or more appropriate place to put this,
    # but my knowledge of ruby and puppet isn't good enough to take risks
    tags = resource[:user_tags]
    tags = [tags] unless tags.is_a?(Array) # array-ify
    tags
  end

  def user_tags
    match = rabbitmqctl('list_users').split(/\n/)[1..-2].collect do |line|
      line.match(/^#{Regexp.escape(resource[:name])}\s+\[(.*)\]/)
    end.compact.first
    if match
      tags=match[1].to_s.split(/,\s*/)
      unless resource[:admin]==:true and !user_tags_get().index("administrator")
        tags
      else
        # admin and user_tags can conflict if admin is set but the user tags 
        # don't include administrator.  This confuses puppet.  So don't report
        # the administrator tag in this case even though present
        tags.delete("administrator")
        tags
      end
    else
      raise Puppet::Error, "Could not match line '#{resource[:name]} (true|false)' from list_users (perhaps you are running on an older version of rabbitmq that does not support user tags?)"
    end
  end

  def user_tags=(state)
    set_user_tags()
  end

  def set_user_tags
    tags=user_tags_get()
    if resource[:admin]==:true and !tags.index("administrator")
      tags.push("administrator") 
    end
    rabbitmqctl('set_user_tags', resource[:name], tags)
  end

end

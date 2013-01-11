require 'puppet'
Puppet::Type.type(:rabbitmq_user).provide(:rabbitmqctl) do

  commands :rabbitmqctl => 'rabbitmqctl'
  defaultfor :feature => :posix

  def self.instances
    rabbitmqctl('list_users').split(/\n/)[1..-2].collect do |line|
      if line =~ /^(\S+)(\s+\[.*\])$/
        new(:name => $1)
      else
        raise Puppet::Error, "Cannot parse invalid user line: #{line}"
      end
    end
  end

  def create
    rabbitmqctl('add_user', resource[:name], resource[:password])
    rabbitmqctl('set_user_tags', resource[:name], resource[:tags]) unless resource[:tags].nil?
  end

  def destroy
    rabbitmqctl('delete_user', resource[:name])
  end

  def exists?
    rabbitmqctl('list_users').split(/\n/)[1..-2].detect do |line|
      line.match(/^#{Regexp.escape(resource[:name])}\s+\[.*\]$/)
    end
  end

  # def password
  # def password=()

  def tags
    tags = get_user_tags
    # prevents resource from being applied on every run if clearing tags with ''
    tags = [''] if tags == []
  end

  def tags=(state)
    rabbitmqctl('set_user_tags', resource[:name], state)
  end

  def get_user_tags
    rabbitmqctl('list_users').split(/\n/)[1..-2].each do |line|
      if line.match(/^#{Regexp.escape(resource[:name])}\s+\[.*\]$/)
        return line.split(/\t/).last[1..-2].gsub(/,\s+/, ',').split(',')
      end
    end
  end

end

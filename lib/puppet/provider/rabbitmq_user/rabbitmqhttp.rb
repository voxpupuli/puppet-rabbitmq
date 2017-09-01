require 'puppet'
require 'set'
require "rabbitmq/http/client"

$endpoint = "http://localhost:15672"
$client = RabbitMQ::HTTP::Client.new($endpoint, :username => "guest", :password => "guest")

Puppet::Type.type(:rabbitmq_user).provide(:rabbitmqhttp, :parent => Puppet::Type.type(:rabbitmq_user).provider(:rabbitmqctl)) do

  defaultfor :feature => :posix

  def create
    $client.create_user(resource[:name], :password => resource[:password])
    if ! resource[:tags].empty?
      set_user_tags(resource[:tags])
    end
  end

  def change_password
      keep_tags = get_user_tags
      set_user_tags(keep_tags)
  end

  def password
    nil
  end

  def check_password
    user = $client.user_info(resource[:name])
    dec_hash = Base64.decode64(user.password_hash)
    salt = dec_hash[0..3]
    sha256 = Digest::SHA256.new
    new_hash = sha256.digest(salt + resource[:password])
    new_pass = Base64.encode64(salt + new_hash)[0..-2]
    if user.password_hash.eql? new_pass
      true
    else
      false
    end
  end

  def destroy
    $client.delete_user(resource[:name])
  end

  def exists?
    v_list = $client.list_users

    out = false
    v_list.each {|line|
      if (line[:name].match(/^#{Regexp.escape(resource[:name])}$/))
          out = true
      end
      }
    return out
  end

  def tags
    tags = get_user_tags
    # do not expose the administrator tag for admins
    if resource[:admin] == :true
      tags.delete('administrator')
    end
    tags.entries.sort
  end

  def tags=(tags)
    if ! tags.nil?
      set_user_tags(tags)
    end
  end

  def admin
    if usertags = get_user_tags
      (:true if usertags.include?('administrator')) || :false
    end
  end

  def admin=(state)
    usertags = get_user_tags
    if state == :true
      usertags.add('administrator')
    else
      usertags.delete('administrator')
    end
    set_user_tags(usertags)
  end

  def set_user_tags(usertags)
    $client.update_user(resource[:name], :password => resource[:password], :tags => usertags.to_a.join(','))
  end

  private
  def get_user_tags
    tags = $client.user_info(resource[:name])
    return Set.new(tags[:tags].split(","))
  end
end

require 'puppet'
require 'set'
require File.expand_path(File.join(File.dirname(__FILE__), '..', 'rabbitmqctl'))
Puppet::Type.type(:rabbitmq_user).provide(:rabbitmqctl, parent: Puppet::Provider::Rabbitmqctl) do
  if Puppet::PUPPETVERSION.to_f < 3
    commands rabbitmqctl: 'rabbitmqctl'
  else
    has_command(:rabbitmqctl, 'rabbitmqctl') do
      environment HOME: '/tmp'
    end
  end

  defaultfor feature: :posix

  def self.instances
    user_list = run_with_retries do
      rabbitmqctl('-q', 'list_users')
    end

    user_list.split(%r{\n}).map do |line|
      raise Puppet::Error, "Cannot parse invalid user line: #{line}" unless line =~ %r{^(\S+)(\s+\[.*?\]|)$}
      new(name: Regexp.last_match(1))
    end
  end

  def create
    raise Puppet::Error, "Password is a required parameter for rabbitmq_user (user: #{name})" if @resource[:password].nil?

    rabbitmqctl('add_user', resource[:name], resource[:password])
    make_user_admin if resource[:admin] == :true
    set_user_tags(resource[:tags]) unless resource[:tags].empty?
  end

  def change_password
    rabbitmqctl('change_password', resource[:name], resource[:password])
  end

  def password
    nil
  end

  def check_password
    response = self.class.run_with_retries do
      rabbitmqctl('eval', 'rabbit_access_control:check_user_pass_login(list_to_binary("' + resource[:name] + '"), list_to_binary("' + resource[:password] + '")).')
    end
    if response.include? 'refused'
      false
    else
      true
    end
  end

  def destroy
    rabbitmqctl('delete_user', resource[:name])
  end

  def exists?
    user_list = self.class.run_with_retries do
      rabbitmqctl('-q', 'list_users')
    end

    user_list.split(%r{\n}).find do |line|
      line.match(%r{^#{Regexp.escape(resource[:name])}(\s+(\[.*?\]|\S+)|)$})
    end
  end

  def tags
    tags = get_user_tags
    # do not expose the administrator tag for admins
    tags.delete('administrator') if resource[:admin] == :true
    tags.entries.sort
  end

  def tags=(tags)
    set_user_tags(tags) unless tags.nil?
  end

  def admin
    usertags = get_user_tags
    raise Puppet::Error, "Could not match line '#{resource[:name]} (true|false)' from list_users (perhaps you are running on an older version of rabbitmq that does not support admin users?)" unless usertags
    (:true if usertags.include?('administrator')) || :false
  end

  def admin=(state)
    if state == :true
      make_user_admin
    else
      usertags = get_user_tags
      usertags.delete('administrator')
      rabbitmqctl('set_user_tags', resource[:name], usertags.entries.sort)
    end
  end

  def set_user_tags(tags) # rubocop:disable Style/AccessorMethodName
    is_admin = get_user_tags.member?('administrator') \
               || resource[:admin] == :true
    usertags = Set.new(tags)
    usertags.add('administrator') if is_admin
    rabbitmqctl('set_user_tags', resource[:name], usertags.entries.sort)
  end

  def make_user_admin
    usertags = get_user_tags
    usertags.add('administrator')
    rabbitmqctl('set_user_tags', resource[:name], usertags.entries.sort)
  end

  private

  def get_user_tags # rubocop:disable Style/AccessorMethodName
    match = rabbitmqctl('-q', 'list_users').split(%r{\n}).map do |line|
      line.match(%r{^#{Regexp.escape(resource[:name])}\s+\[(.*?)\]})
    end.compact.first
    Set.new(match[1].split(' ').map { |x| x.gsub(%r{,$}, '') }) if match
  end
end

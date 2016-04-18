require 'puppet/provider/rabbitmqctl'

Puppet::Type.type(:rabbitmq_user).provide(
  :rabbitmqctl,
  :parent => Puppet::Provider::Rabbitmqctl
) do

  if Puppet::PUPPETVERSION.to_f < 3
    commands :rabbitmqctl => 'rabbitmqctl'
  else
     has_command(:rabbitmqctl, 'rabbitmqctl') do
       environment :HOME => "/tmp"
     end
  end

  defaultfor :feature => :posix

  def initialize(value={})
    super(value)
    @property_flush = {}
  end

  def self.instances
    self.run_with_retries {
      rabbitmqctl('-q', 'list_users')
    }.split(/\n/).collect do |line|
      if line =~ /^(\S+)\s+\[(.*?)\]$/
        new(
          :ensure => :present,
          :name   => $1,
          :tags   => $2.split(/,\s*/)
        )
      else
        raise Puppet::Error, "Cannot parse invalid user line: #{line}"
      end
    end
  end

  def self.prefetch(resources)
    users = instances
    resources.each_key do |user|
      if provider = users.find { |u| u.name == user }
        resources[user].provider = provider
      end
    end
  end

  def exists?
    @property_hash[:ensure] == :present
  end

  def create
    rabbitmqctl('add_user', @resource[:name], @resource[:password])

    tags = @resource[:tags]
    tags << admin_tag if @resource[:admin] == :true
    rabbitmqctl('set_user_tags', @resource[:name], tags) unless tags.empty?

    @property_hash[:ensure] = :present
  end

  def destroy
    rabbitmqctl('delete_user', @resource[:name])
    @property_hash[:ensure] = :absent
  end

  def password=(password)
    rabbitmqctl('change_password', @resource[:name], password)
  end

  def password
  end

  def check_password(password)
    check_access_control = [
      'rabbit_access_control:check_user_pass_login',
      %Q[(list_to_binary("#{@resource[:name]}"), ],
      %Q[list_to_binary("#{password}")).]
    ]

    response = rabbitmqctl('eval', check_access_control.join)
    !response.include? 'refused'
  end

  def tags
    # do not expose the administrator tag for admins
    @property_hash[:tags].reject { |tag| tag == admin_tag }
  end

  def tags=(tags)
    @property_flush[:tags] = tags
  end

  def admin
    @property_hash[:tags].include?(admin_tag) ? :true : :false
  end

  def admin=(state)
    @property_flush[:admin] = state
  end

  def flush
    unless @property_flush.empty?
      tags = @property_flush[:tags] || @resource[:tags]
      tags << admin_tag if @resource[:admin] == :true
      rabbitmqctl('set_user_tags', @resource[:name], tags)
      @property_flush.clear
    end
  end

  private
  def admin_tag
    'administrator'
  end

end

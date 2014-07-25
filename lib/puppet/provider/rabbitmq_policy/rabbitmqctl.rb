Puppet::Type.type(:rabbitmq_policy).provide(:rabbitmqctl) do

  if Puppet::PUPPETVERSION.to_f < 3
    commands :rabbitmqctl => 'rabbitmqctl'
  else
     has_command(:rabbitmqctl, 'rabbitmqctl') do
       environment :HOME => "/tmp"
     end
  end

  defaultfor :feature=> :posix

  def self.instances
    []
  end

  # cache vhost policies
  def self.vhost_policies(name, vhost)
    @policies = {} unless @policies

    unless @policies[vhost]
      @policies[vhost] = {}

      rabbitmqctl('list_policies', '-p', vhost).split(/\n/)[1..-2].collect do |line|
        if line =~ /^(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)$/
          @policies[$1][$2] = {
            :vhost      => $1,
            :pattern    => $4,
            :apply_to   => $3,
            :definition => $5,
            :priority   => $6,
          }
        else
          raise Puppet::Error, "cannot parse line from list_policies:#{line}"
        end
      end
    end

    @policies[vhost][name]
  end

  def vhost_policies(name, vhost)
    self.class.vhost_policies(name, vhost)
  end

  def create
    rabbitmqctl('set_policy', resource[:name], resource[:pattern], resource[:definition], '-p', resource[:vhost], '--priority', resource[:priority], '--apply-to', resource[:apply_to])
  end

  def destroy
    rabbitmqctl('clear_policy', resource[:name], '-p', resource[:vhost])
  end

  # I am implementing prefetching in exists b/c I need to be sure
  # that the rabbitmq package is installed before I make this call.
  def exists?
    vhost_policies(resource[:name], resource[:vhost])
  end

  def vhost
    vhost_policies(resource[:name], resource[:vhost])[:vhost]
  end

  def vhost=(vh)
    set_policy
  end

  def pattern
    vhost_policies(resource[:name], resource[:vhost])[:pattern]
  end

  def pattern=(reg)
    set_policy
  end

  def definition
    vhost_policies(resource[:name], resource[:vhost])[:definition]
  end

  def definition=(json)
    set_policy
  end

  def priority
    vhost_policies(resource[:name], resource[:vhost])[:priority]
  end

  def priority=(level)
    set_policy
  end

  def apply_to
    vhost_policies(resource[:name], resource[:vhost])[:apply_to]
  end

  def apply_to=(to)
    set_policy
  end

  # implement memoization so that we only call set_policy once
  def set_policy
    unless @policy_set
      @policy_set = true

      resource[:vhost]      ||= vhost
      resource[:pattern]    ||= pattern
      resource[:definition] ||= definition
      resource[:priority]   ||= priority
      resource[:apply_to]   ||= apply_to

      rabbitmqctl('set_policy', resource[:name], resource[:pattern], resource[:definition], '-p', resource[:vhost], '--priority', resource[:priority], '--apply-to', resource[:apply_to])
    end
  end

end

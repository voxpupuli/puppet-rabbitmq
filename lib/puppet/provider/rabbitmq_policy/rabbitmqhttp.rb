require 'json'
require 'puppet/util/package'

require "rabbitmq/http/client"

$endpoint = "http://localhost:15672"
$client = RabbitMQ::HTTP::Client.new($endpoint, :username => "guest", :password => "guest")

Puppet::Type.type(:rabbitmq_policy).provide(:rabbitmqhttp, :parent => Puppet::Type.type(:rabbitmq_policy).provider(:rabbitmqctl)) do

  defaultfor :feature => :posix
  # cache policies
  def self.policies(name, vhost)
    @policies = {} unless @policies
    unless @policies[vhost]
      @policies[vhost] = {}
      vhost_policies = $client.list_policies(vhost)
      vhost_policies.each do |line|
      if line.vhost.eql? vhost
        @policies[vhost][line.name] = {
          :applyto    => line["apply-to"],
          :pattern    => line.pattern,
          :definition => line.definition,
          :priority   => line.priority}
        end
      end
    end
    @policies[vhost][name]
  end

  def policies(name, vhost)
    self.class.policies(vhost, name)
  end

  def should_policy
    @should_policy ||= resource[:name].rpartition('@').first
  end

  def should_vhost
    @should_vhost ||= resource[:name].rpartition('@').last
  end

  def create
    set_policy
  end

  def destroy
    rabbitmqctl('clear_policy', '-p', should_vhost, should_policy)
  end

  def exists?
    policies(should_vhost, should_policy)
  end

  def pattern
    policies(should_vhost, should_policy)[:pattern]
  end

  def pattern=(pattern)
    set_policy
  end

  def applyto
    policies(should_vhost, should_policy)[:applyto]
  end

  def applyto=(applyto)
    set_policy
  end

  def definition
    policies(should_vhost, should_policy)[:definition]
  end

  def definition=(definition)
    set_policy
  end

  def priority
    policies(should_vhost, should_policy)[:priority]
  end

  def priority=(priority)
    set_policy
  end

  def set_policy
    unless @set_policy
      @set_policy = true
      resource[:applyto]    ||= applyto
      resource[:definition] ||= definition
      resource[:pattern]    ||= pattern
      resource[:priority]   ||= priority

      attributes = {:definition => resource[:definition], :priority => resource[:priority], :pattern => resource[:pattern]}

      $client.update_policies_of(should_vhost, should_policy, attributes)

    end
  end
end


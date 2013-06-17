require "rubygems"
require "amqp"

Puppet::Type.type(:rabbitmq_exchange).provide(:amqp) do

	commands :rabbitmqctl => 'rabbitmqctl'
	defaultfor :feature=> :posix


	def initialize(*args)
		super


		# Get all exchanges for current VHOST, if we haven't done so already
		# Can't do this in instances as it is only done once and won't grab all
		# VHOSTS, this way is more efficient as we don't end up listing all VHOSTS
		# if we don't need them.
		value = resource[:name].split(/@/)
		exchangeName = value[0]
		vhost = value[1]

		if ! defined? @exchanges
			@exchanges = {}
		end

		lines = rabbitmqctl('list_exchanges', '-p', vhost).split(/\n/)
		lines.shift()
		lines.pop()

		lines.map do |line|
			retValue = line.split(/\t/)
			@exchanges["#{retValue[0]}@#{vhost}"] = retValue
		end
	end


	def create
		value = resource[:name].split(/@/)
		exchangeName = value[0]
		vhost = value[1]

		info("Creating: #{exchangeName}")
		EventMachine.run do
			AMQP.connect(
				:host => @resource[:host],
				:port => @resource[:port],
				:vhost => vhost,
				:user => @resource[:user],
				:pass => @resource[:pass]
			) do |connection|
				AMQP::Channel.new(connection) do |channel|
					newExhange = AMQP::Exchange.new(channel, @resource[:exchange_type], exchangeName)
					connection.close { EventMachine.stop }
				end
			end
		end
	end

	def destroy
		value = resource[:name].split(/@/)
		exchangeName = value[0]
		vhost = value[1]

		info("Destroying: #{exchangeName}")
		EventMachine.run do
			AMQP.connect(
				:host => @resource[:host],
				:port => @resource[:port],
				:vhost => vhost,
				:user => @resource[:user],
				:pass => @resource[:pass]
			) do |connection|
				AMQP::Channel.new(connection) do |channel|
					exchange = AMQP::Exchange.new(channel, @resource[:exchange_type], exchangeName)
					exchange.delete
					connection.close { EventMachine.stop }
				end
			end
		end
	end

	def exists?
		@exchanges.has_key?(@resource[:name])
	end


	# Define getter and setter for Exchange Type
	def exchange_type
		@exchanges[@resource[:name]][1]
	end

	def exchange_type=(type)
		value = resource[:name].split(/@/)
		exchangeName = value[0]
		vhost = value[1]

		info("Changing: #{exchangeName}")
		EventMachine.run do
			AMQP.connect(
				:host => @resource[:host],
				:port => @resource[:port],
				:vhost => vhost,
				:user => @resource[:user],
				:pass => @resource[:pass]
			) do |connection|
				AMQP::Channel.new(connection) do |channel|
					exchange = AMQP::Exchange.new(channel, self.exchange_type, exchangeName)
					exchange.delete
					newExhange = AMQP::Exchange.new(channel, @resource.should(:exchange_type), exchangeName)
					connection.close { EventMachine.stop }
				end
			end
		end
	end

end

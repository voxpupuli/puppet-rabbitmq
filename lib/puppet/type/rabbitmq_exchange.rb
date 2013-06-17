Puppet::Type.newtype(:rabbitmq_exchange) do
	desc 'Native type for managing rabbitmq exchanges'

	ensurable do
		defaultto(:present)
		newvalue(:present) do
			provider.create
		end
		newvalue(:absent) do
			provider.destroy
		end
	end

	newparam(:name, :namevar => true) do
		desc 'Name of the exchange'
		newvalues(/^\S+$/)
	end


	newparam(:host) do
		desc 'Hostname of rabbitmq server.'
		newvalues(/^\S+$/)
		defaultto 'localhost'
	end

	newparam(:port) do
		desc 'AMQP port of rabbitmq server.'
		newvalues(/^\d+$/)
		defaultto 5672
	end

	newparam(:user) do
		desc 'Username to use when connecting to rabbitmq server'
		newvalues(/^\S+$/)
		defaultto 'guest'
	end

	newparam(:pass) do
		desc 'Password to use when connecting to rabbitmq server'
		newvalues(/^\S+$/)
		defaultto 'guest'
	end


	newproperty(:exchange_type) do
		desc 'Type of exchange'
		newvalue('direct')
		newvalue('fanout')
		newvalue('topic')
		newvalue('headers')
		defaultto :direct
	end

end

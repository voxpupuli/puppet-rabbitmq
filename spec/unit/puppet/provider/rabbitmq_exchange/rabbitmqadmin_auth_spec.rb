require 'puppet'
require 'mocha'
RSpec.configure do |config|
  config.mock_with :mocha
end
provider_class = Puppet::Type.type(:rabbitmq_exchange).provider(:rabbitmqadmin)
describe provider_class do
  before :each do
    @resource = Puppet::Type::Rabbitmq_exchange.new(
      {:name => 'mcollective_broadcast@/mcollective',
       :type => :topic,
       :user => 'mcollective',
       :password => 'changeme'}
    )
    @provider = provider_class.new(@resource)
  end

  it 'should call rabbitmqadmin to create' do
    @provider.expects(:rabbitmqadmin).with('declare', 'exchange',
                                           '--username=mcollective', '--password=changeme',
                                           '--vhost=/mcollective', 'name=mcollective_broadcast', 'type=topic')
    @provider.create
  end

  it 'should call rabbitmqadmin to destroy' do
    @provider.expects(:rabbitmqadmin).with('delete', 'exchange',
                                           '--username=mcollective', '--password=changeme',
                                           '--vhost=/mcollective', 'name=mcollective_broadcast')
    @provider.destroy
  end
end

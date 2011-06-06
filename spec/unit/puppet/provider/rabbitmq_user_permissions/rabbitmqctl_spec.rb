require 'puppet'
require 'mocha'
RSpec.configure do |config|
  config.mock_with :mocha
end
provider_class = Puppet::Type.type(:rabbitmq_user_permissions).provider(:rabbitmqctl)
describe provider_class do
  before :each do
    @resource = Puppet::Type::Rabbitmq_user_permissions.new(
      {:name => 'foo@bar'}
    )
    @provider = provider_class.new(@resource)
  end
  it 'should match user permissions from list' do
    @provider.expects(:rabbitmqctl).with('list_user_permissions', 'foo').returns <<-EOT
Listing users ...
bar 1 2 3
...done. 
EOT
    @provider.exists?.should == 'bar 1 2 3'
  end
  it 'should not match user permissions with more than 3 columns' do
    @provider.expects(:rabbitmqctl).with('list_user_permissions', 'foo').returns <<-EOT
Listing users ...
bar 1 2 3 4
...done. 
EOT
    @provider.exists?.should == nil
  end
  it 'should not match an empty list' do
    @provider.expects(:rabbitmqctl).with('list_user_permissions', 'foo').returns <<-EOT
Listing users ...
...done. 
EOT
    @provider.exists?.should == nil
  end
  it 'should create default permissions' do
    @provider.instance_variable_set(:@should_vhost, "bar")
    @provider.instance_variable_set(:@should_user, "foo")
    @provider.expects(:rabbitmqctl).with('set_permissions', '-p', 'bar', 'foo', '""', '""', '""')
    @provider.create 
  end
  it 'should destroy permissions' do
    @provider.instance_variable_set(:@should_vhost, "bar")
    @provider.instance_variable_set(:@should_user, "foo")
    @provider.expects(:rabbitmqctl).with('clear_permissions', '-p', 'bar', 'foo')
    @provider.destroy 
  end
end

require 'puppet'
require 'mocha'
RSpec.configure do |config|
  config.mock_with :mocha
end
provider_class = Puppet::Type.type(:rabbitmq_user).provider(:rabbitmqctl)
describe provider_class do
  before :each do
    @resource = Puppet::Type::Rabbitmq_user.new(
      {:name => 'foo', :password => 'bar'}
    )
    @provider = provider_class.new(@resource)
  end
  it 'should match user names' do
    @provider.expects(:rabbitmqctl).with('list_users').returns <<-EOT
Listing users ...
foo []
...done.
EOT
    @provider.exists?.should == 'foo []'
  end
  it 'should not match if no users on system' do
    @provider.expects(:rabbitmqctl).with('list_users').returns <<-EOT
Listing users ...
...done.
EOT
    @provider.exists?.should be_nil
  end
  it 'should not match if no matching users on system' do
    @provider.expects(:rabbitmqctl).with('list_users').returns <<-EOT
Listing users ...
fooey []
...done.
EOT
    @provider.exists?.should be_nil
  end
  it 'should match user names from list' do
    @provider.expects(:rabbitmqctl).with('list_users').returns <<-EOT
Listing users ...
one []
two three []
foo []
bar []
...done.
EOT
    @provider.exists?.should == 'foo []'
  end
  it 'should create user and set password' do
    @resource[:password] = 'bar'
    @provider.expects(:rabbitmqctl).with('add_user', 'foo', 'bar')
    @provider.create
  end
  it 'shoud create user, set password and set tags to foo and bar' do
    @resource[:password] = 'bar'
    @resource[:tags] = ['foo', 'bar']
    @provider.expects(:rabbitmqctl).with('add_user', 'foo', 'bar')
    @provider.expects(:rabbitmqctl).with('set_user_tags', 'foo', ['foo', 'bar'])
    @provider.create
  end  
  it 'should call rabbitmqctl to delete' do
    @provider.expects(:rabbitmqctl).with('delete_user', 'foo')
    @provider.destroy
  end
end
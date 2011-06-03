require 'puppet'
require 'mocha'
RSpec.configure do |config|
  config.mock_with :mocha
end
provider_class = Puppet::Type.type(:rabbitmq_user).provider(:rabbitmqctl)
describe provider_class do
  before :each do
    @resource = Puppet::Type::Rabbitmq_user.new(
      {:name => 'foo'}
    )
    @provider = provider_class.new(@resource)
  end
  it 'should match user names' do
    @provider.expects(:rabbitmqctl).with('list_users').returns <<-EOT
Listing users ...
foo
...done.
EOT
    @provider.exists?.should == 'foo'
  end
  it 'should match user names with 2.4.1 syntax' do
    @provider.expects(:rabbitmqctl).with('list_users').returns <<-EOT
Listing users ...
foo bar
...done.
EOT
    @provider.exists?.should == 'foo bar'
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
fooey
...done.
EOT
    @provider.exists?.should be_nil
  end
  it 'should match user names from list' do
    @provider.expects(:rabbitmqctl).with('list_users').returns <<-EOT
Listing users ...
one
two three
foo
bar
...done.
EOT
    @provider.exists?.should == 'foo'
  end
  it 'should fail if no password is set on user create' do
    expect { @provider.create }.should raise_error(ArgumentError, 'must set password when creating user')
  end
  it 'should create user and set password' do
    @resource[:password] = 'bar'
    @provider.expects(:rabbitmqctl).with('add_user', 'foo', 'bar')
    @provider.create
  end
  it 'should call rabbitmqctl to create' do
    @provider.expects(:rabbitmqctl).with('delete_user', 'foo')
    @provider.destroy
  end
end

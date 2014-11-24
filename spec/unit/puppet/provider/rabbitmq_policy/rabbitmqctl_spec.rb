require 'puppet'
require 'mocha'
RSpec.configure do |config|
  config.mock_with :mocha
end
provider_class = Puppet::Type.type(:rabbitmq_policy).provider(:rabbitmqctl)
describe provider_class do
  before :each do
    @resource = Puppet::Type::Rabbitmq_policy.new(
      {:name => 'foo',
       :match => '.*',
       :policy => '{"ha-mode": "all"}',
      }
    )
    @provider = provider_class.new(@resource)
  end
  it 'should match policy names' do
    @provider.expects(:rabbitmqctl).with('-q', 'list_policies', '-p', '/').returns <<-EOT
Listing policies ...
/	foo	all	.*	{"ha-mode":"all"}	0
...done.
EOT
    @provider.exists?.should == '/	foo	all	.*	{"ha-mode":"all"}	0'
  end
  it 'should not match if no policies on system' do
    @provider.expects(:rabbitmqctl).with('-q', 'list_policies', '-p', '/').returns <<-EOT
Listing policies ...
...done.
EOT
    @provider.exists?.should be_nil
  end
  it 'should not match if no matching policies on system' do
    @provider.expects(:rabbitmqctl).with('-q', 'list_policies', '-p', '/').returns <<-EOT
Listing policies ...
/	fooey	all	.*	{"ha-mode":"all"}	0
...done.
EOT
    @provider.exists?.should be_nil
  end
  it 'should call rabbitmqctl to create' do
    @provider.expects(:rabbitmqctl).with('-q', 'set_policy', '-p', '/', 'foo', '.*', '{"ha-mode": "all"}')
    @provider.create
  end
  it 'should call rabbitmqctl to delete' do
    @provider.expects(:rabbitmqctl).with('-q', 'clear_policy', '-p', '/', 'foo')
    @provider.destroy
  end
end


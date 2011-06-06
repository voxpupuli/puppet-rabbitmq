require 'puppet'
require 'puppet/type/rabbitmq_user_permissions'
describe Puppet::Type.type(:rabbitmq_user_permissions) do
  before :each do
    @perms = Puppet::Type.type(:rabbitmq_user_permissions).new(:name => 'foo@bar')
  end
  it 'should accept a valid hostname name' do
    @perms[:name] = 'dan@bar'
    @perms[:name].should == 'dan@bar'
  end
  it 'should require a name' do
    expect { Puppet::Type.type(:rabbitmq_user_permissions).new({}) }.should raise_error(Puppet::Error, 'Title or name must be provided')
  end
  it 'should fail when names dont have a @' do
    expect {  @perms[:name] = 'bar' }.should raise_error(Puppet::Error, /Valid values match/)
  end
  [:configure_permission, :read_permission, :write_permission].each do |param|
    it 'should default to ""' do
       @perms[param].should == '""'
    end
    it "should accept a valid regex for #{param}" do
      @perms[param] = '.*?'
      @perms[param].should == '.*?'  
    end
    it "should not accept invalid regex for #{param}" do
      expect { @perms[param] = '*' }.should raise_error(Puppet::Error, /Invalid regexp/)
    end
  end
end

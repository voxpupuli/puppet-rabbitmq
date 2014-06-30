require 'puppet'
require 'puppet/type/rabbitmq_policy'
describe Puppet::Type.type(:rabbitmq_policy) do
  before :each do
    @policy = Puppet::Type.type(:rabbitmq_policy).new(:name => 'foo')
  end
  it 'should set correct defaults' do
    @policy[:vhost].should == '/'
    @policy[:priority].should == '0'
    @policy[:apply_to].should == 'all'
  end
  it 'should accept a name' do
    @policy[:name] = 'mypolicy'
    @policy[:name].should == 'mypolicy'
  end
  it 'should accept a vhost' do
    @policy[:vhost] = 'myvhost'
    @policy[:vhost].should == 'myvhost'
  end
  it 'should accept a pattern' do
    @policy[:pattern] = '.*'
    @policy[:pattern].should == '.*'
  end
  it 'should accept a priority' do
    @policy[:priority] = 1
    @policy[:priority].should == 1
  end
  ['exchanges', 'queues', 'all'].each do |val|
    it 'apply_to property should accept #{val}' do
      @policy[:apply_to] = val
      @policy[:apply_to].should == val
    end
  end
  it 'should accept a definition' do
    @policy[:definition] = {'foo' => 'foo'}
    @policy[:definition].should == {'foo' => 'foo'}
  end
  it 'should require a name' do
    expect {
      Puppet::Type.type(:rabbitmq_policy).new({})
    }.to raise_error(Puppet::Error, 'Title or name must be provided')
  end
  it 'should not allow whitespace in the name' do
    expect {
      @policy[:name] = 'b r'
    }.to raise_error(Puppet::Error, /Valid values match/)
  end
  it 'should not allow whitespace in the vhost' do
    expect {
      @policy[:vhost] = 'b r'
    }.to raise_error(Puppet::Error, /Valid values match/)
  end
  it 'should not allow a non-digit values for priority' do
    expect {
      @policy[:priority] = 'foo'
    }.to raise_error(Puppet::Error, /Valid values match/)
  end
  it 'should not allow an unknown value for apply_to' do
    expect {
      @policy[:apply_to] = 'nothing'
    }.to raise_error(Puppet::Error, /Invalid value/)
  end
  it 'should not allow a non-Hash values for definition' do
    expect {
      @policy[:definition] = 'foo'
    }.to raise_error(Puppet::Error, /must be a non-empty Hash/)
  end
  it 'should not allow an empty Hash value for definition' do
    expect {
      @policy[:definition] = {}
    }.to raise_error(Puppet::Error, /must be a non-empty Hash/)
  end
  it "should autorequire rabbitmq_vhost" do
    vhost = Puppet::Type.type(:rabbitmq_vhost).new(:name => "myvhost")
    depend  = Puppet::Type.type(:rabbitmq_policy).new(:name => 'foo', :vhost => 'myvhost')
    config = Puppet::Resource::Catalog.new :testing do |conf|
      [vhost, depend].each { |resource| conf.add_resource resource }
    end
    rel = depend.autorequire[0]
    rel.source.ref.should == vhost.ref
    rel.target.ref.should == depend.ref
  end
end

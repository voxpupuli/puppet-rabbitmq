require 'puppet'
require 'puppet/type/rabbitmq_federation_upstream'
describe Puppet::Type.type(:rabbitmq_federation_upstream) do
  before :each do
    @federation_upstream = Puppet::Type.type(:rabbitmq_federation_upstream).new(:name => 'foo')
  end
  it 'should set correct defaults' do
    @federation_upstream[:vhost].should == '/'
    @federation_upstream[:max_hops].should == '1'
    @federation_upstream[:prefetch_count].should == '1000'
    @federation_upstream[:reconnect_delay].should == '1'
    @federation_upstream[:ack_mode].should == 'on-confirm'.to_s.to_sym
    @federation_upstream[:trust_user_id].should == :false
  end
  it 'should accept a name' do
    @federation_upstream[:name] = 'myfederation'
    @federation_upstream[:name].should == 'myfederation'
  end
  it 'should accept a vhost' do
    @federation_upstream[:vhost] = 'myvhost'
    @federation_upstream[:vhost].should == 'myvhost'
  end
  it 'should accept a uri' do
    @federation_upstream[:uri] = 'amqp://foouser:foo@localhost/'
    @federation_upstream[:uri].should == ['amqp://foouser:foo@localhost/']
  end
  it 'should accept expires' do
    @federation_upstream[:expires] = 100
    @federation_upstream[:expires].should == 100
  end
  it 'should accept message_ttl' do
    @federation_upstream[:message_ttl] = 100
    @federation_upstream[:message_ttl].should == 100
  end
  it 'should accept max_hops' do
    @federation_upstream[:max_hops] = 2
    @federation_upstream[:max_hops].should == 2
  end
  it 'should accept a prefetch_count' do
    @federation_upstream[:prefetch_count] = 100
    @federation_upstream[:prefetch_count].should == 100
  end
  it 'should accept a reconnect_delay' do
    @federation_upstream[:reconnect_delay] = 2
    @federation_upstream[:reconnect_delay].should == 2
  end
  ['no-ack', 'on-confirm', 'on-publish'].each do |val|
    it 'ack_mode property should accept #{val}' do
      @federation_upstream[:ack_mode] = val
      @federation_upstream[:ack_mode].should == val.to_s.to_sym
    end
  end
  [true, false].each do |val|
    it 'trust_user_id property should accept #{val}' do
      @federation_upstream[:trust_user_id] = val
      @federation_upstream[:trust_user_id].should == val.to_s.to_sym
    end
  end
  it 'should require a name' do
    expect {
      Puppet::Type.type(:rabbitmq_federation_upstream).new({})
    }.to raise_error(Puppet::Error, 'Title or name must be provided')
  end
  it 'should not allow whitespace in the name' do
    expect {
      @federation_upstream[:name] = 'b r'
    }.to raise_error(Puppet::Error, /Valid values match/)
  end
  it 'should not allow whitespace in the vhost' do
    expect {
      @federation_upstream[:vhost] = 'b r'
    }.to raise_error(Puppet::Error, /Valid values match/)
  end
  it 'should not allow whitespace in the uri' do
    expect {
      @federation_upstream[:uri] = 'amqp:// localhost/'
    }.to raise_error(Puppet::Error, /Valid values match/)
  end
  it 'should not allow a non-amqp uri' do
    expect {
      @federation_upstream[:uri] = 'foo://localhost/'
    }.to raise_error(Puppet::Error, /Valid values match/)
  end
  it 'should not allow a non-digit values for expires' do
    expect {
      @federation_upstream[:expires] = 'foo'
    }.to raise_error(Puppet::Error, /Valid values match/)
  end
  it 'should not allow a non-digit values for message_ttl' do
    expect {
      @federation_upstream[:message_ttl] = 'foo'
    }.to raise_error(Puppet::Error, /Valid values match/)
  end
  it 'should not allow a non-digit values for max_hops' do
    expect {
      @federation_upstream[:max_hops] = 'foo'
    }.to raise_error(Puppet::Error, /Valid values match/)
  end
  it 'should not allow a non-digit values for prefetch_count' do
    expect {
      @federation_upstream[:prefetch_count] = 'foo'
    }.to raise_error(Puppet::Error, /Valid values match/)
  end
  it 'should not allow a non-digit values for reconnect_delay' do
    expect {
      @federation_upstream[:reconnect_delay] = 'foo'
    }.to raise_error(Puppet::Error, /Valid values match/)
  end
  it 'should not allow an unknown value for ack_mode' do
    expect {
      @federation_upstream[:ack_mode] = 'never-ack'
    }.to raise_error(Puppet::Error, /Invalid value/)
  end
  it 'should not allow a non-boolean values for trust_user_id' do
    expect {
      @federation_upstream[:trust_user_id] = 'foo'
    }.to raise_error(Puppet::Error, /Invalid value/)
  end
  it "should autorequire rabbitmq_vhost" do
    vhost = Puppet::Type.type(:rabbitmq_vhost).new(:name => "myvhost")
    depend  = Puppet::Type.type(:rabbitmq_federation_upstream).new(:name => 'foo', :vhost => 'myvhost')
    config = Puppet::Resource::Catalog.new :testing do |conf|
      [vhost, depend].each { |resource| conf.add_resource resource }
    end
    rel = depend.autorequire[0]
    rel.source.ref.should == vhost.ref
    rel.target.ref.should == depend.ref
  end
end

require 'puppet'
require 'puppet/type/rabbitmq_federation_upstreamset'
describe Puppet::Type.type(:rabbitmq_federation_upstreamset) do
  before :each do
    @federation_upstreamset = Puppet::Type.type(:rabbitmq_federation_upstreamset).new(:name => 'foo')
  end
  it 'should set correct defaults' do
    @federation_upstreamset[:vhost].should == '/'
  end
  it 'should accept a name' do
    @federation_upstreamset[:name] = 'myfederationset'
    @federation_upstreamset[:name].should == 'myfederationset'
  end
  it 'should accept a vhost' do
    @federation_upstreamset[:vhost] = 'myvhost'
    @federation_upstreamset[:vhost].should == 'myvhost'
  end
  it 'should accept an array of upstreams' do
    @federation_upstreamset[:upstreams] = ['myupstream', 'myupstream']
    @federation_upstreamset[:upstreams].should == ['myupstream', 'myupstream']
  end
  it 'should require a name' do
    expect {
      Puppet::Type.type(:rabbitmq_federation_upstreamset).new({})
    }.to raise_error(Puppet::Error, 'Title or name must be provided')
  end
  it 'should not allow whitespace in the name' do
    expect {
      @federation_upstreamset[:name] = 'b r'
    }.to raise_error(Puppet::Error, /Valid values match/)
  end
  it 'should not allow whitespace in the vhost' do
    expect {
      @federation_upstreamset[:vhost] = 'b r'
    }.to raise_error(Puppet::Error, /Valid values match/)
  end
  it 'should not allow whitespace in the upstreams' do
    expect {
      @federation_upstreamset[:upstreams] = ['b r']
    }.to raise_error(Puppet::Error, /No spaces allowed/)
  end
  it 'should not allow "all" in the upstreams property array' do
    expect {
      @federation_upstreamset[:upstreams] = ['all']
    }.to raise_error(Puppet::Error, /"all" cannot be configured/)
  end
  it "should autorequire rabbitmq_vhost" do
    vhost = Puppet::Type.type(:rabbitmq_vhost).new(:name => "myvhost")
    depend  = Puppet::Type.type(:rabbitmq_federation_upstreamset).new(:name => 'foo', :vhost => 'myvhost')
    config = Puppet::Resource::Catalog.new :testing do |conf|
      [vhost, depend].each { |resource| conf.add_resource resource }
    end
    rel = depend.autorequire[0]
    rel.source.ref.should == vhost.ref
    rel.target.ref.should == depend.ref
  end
end

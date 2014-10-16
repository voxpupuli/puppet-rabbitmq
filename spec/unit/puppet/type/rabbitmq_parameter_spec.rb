require 'puppet'
require 'puppet/type/rabbitmq_parameter'
describe Puppet::Type.type(:rabbitmq_parameter) do
  before :each do
    @parameter = Puppet::Type.type(:rabbitmq_parameter).new(:title => 'foovhost foocomponent fooname')
  end
  it 'should parse title pattern' do
    @parameter[:vhost] = 'foovhost'
    @parameter[:component] = 'foocomponent'
    @parameter[:name] = 'fooname'
  end
  it 'should accept a name' do
    @parameter[:name] = 'myparameter'
    @parameter[:name].should == 'myparameter'
  end
  it 'should accept a vhost' do
    @parameter[:vhost] = 'myvhost'
    @parameter[:vhost].should == 'myvhost'
  end
  it 'should accept a component' do
    @parameter[:component] = 'mycomponent'
    @parameter[:component].should == 'mycomponent'
  end
  it 'should accept a value' do
    @parameter[:value] = {'foo' => 'foo'}
    @parameter[:value].should == {'foo' => 'foo'}
  end
  it 'should require a vhost, component and name in title' do
    expect {
      Puppet::Type.type(:rabbitmq_parameter).new({:title => 'foovhost'})
    }.to raise_error(Puppet::Error, /No set of title patterns matched/)
    expect {
      Puppet::Type.type(:rabbitmq_parameter).new({:title => 'foovhost foocomponent'})
    }.to raise_error(Puppet::Error, /No set of title patterns matched/)
  end
  # Federation classes should be used to configure federation components to avoid errors
  it 'should not allow a federation component' do
    expect {
      @parameter[:component] = 'federationx'
    }.to raise_error(Puppet::Error, /Component invalid/)
  end
  it 'should not allow a non-Hash values for value' do
    expect {
      @parameter[:value] = 'foo'
    }.to raise_error(Puppet::Error, /must be a non-empty Hash/)
  end
  it 'should not allow an empty Hash value for value' do
    expect {
      @parameter[:value] = {}
    }.to raise_error(Puppet::Error, /must be a non-empty Hash/)
  end
  it "should autorequire rabbitmq_vhost" do
    vhost = Puppet::Type.type(:rabbitmq_vhost).new(:name => "myvhost")
    depend  = Puppet::Type.type(:rabbitmq_parameter).new(:title => 'myvhost foocomponent fooname')
    config = Puppet::Resource::Catalog.new :testing do |conf|
      [vhost, depend].each { |resource| conf.add_resource resource }
    end
    rel = depend.autorequire[0]
    rel.source.ref.should == vhost.ref
    rel.target.ref.should == depend.ref
  end
end

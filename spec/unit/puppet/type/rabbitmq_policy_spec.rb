require 'puppet'
require 'puppet/type/rabbitmq_policy'
describe Puppet::Type.type(:rabbitmq_policy) do
  before :each do
    @policy = Puppet::Type.type(:rabbitmq_policy).new(
      :name => 'foo',
      :policy => 'foo',
      :match => 'foo',
    )
  end

  it 'should accept a name' do
    @policy[:name] = 'dan'
    @policy[:name].should == 'dan'
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

  it 'should accept a vhost name' do
    @policy[:vhost] = 'dan'
    @policy[:vhost].should == 'dan'
  end
  it 'should not allow whitespace in the vhost' do
    expect {
      @policy[:vhost] = 'b r'
    }.to raise_error(Puppet::Error, /Valid values match/)
  end

  it 'should accept a policy' do
    @policy[:policy] = 'dan'
    @policy[:policy].should == 'dan'
  end
  it 'should require a policy' do
    expect {
      Puppet::Type.type(:rabbitmq_policy).new({
        :ensure => :present,
        :name => 'foo',
        :match => 'foo'})
    }.to raise_error(Puppet::ResourceError, 'Validation of Rabbitmq_policy[foo] failed: must set policy and match')
  end

  it 'should accept a match' do
    @policy[:match] = 'dan'
    @policy[:match].should == 'dan'
  end
  it 'should require a match' do
    expect {
      Puppet::Type.type(:rabbitmq_policy).new({
        :ensure => :present,
        :name => 'foo',
	:policy => 'foo'})
    }.to raise_error(Puppet::ResourceError, 'Validation of Rabbitmq_policy[foo] failed: must set policy and match')
  end
end


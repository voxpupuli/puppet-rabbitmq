require 'puppet'
require 'puppet/type/rabbitmq_binding'
describe Puppet::Type.type(:rabbitmq_binding) do
  before do
    @binding = Puppet::Type.type(:rabbitmq_binding).new(
      name: 'foo@blub@bar',
      destination_type: :queue
    )
  end
  it 'accepts an queue name' do
    @binding[:name] = 'dan@dude@pl'
    @binding[:name].should == 'dan@dude@pl'
  end
  it 'requires a name' do
    expect do
      Puppet::Type.type(:rabbitmq_binding).new({})
    end.to raise_error(Puppet::Error, 'Title or name must be provided')
  end
  it 'does not allow whitespace in the name' do
    expect do
      @binding[:name] = 'b r'
    end.to raise_error(Puppet::Error, %r{Valid values match})
  end
  it 'does not allow names without one @' do
    expect do
      @binding[:name] = 'b_r'
    end.to raise_error(Puppet::Error, %r{Valid values match})
  end

  it 'does not allow names without two @' do
    expect do
      @binding[:name] = 'b@r'
    end.to raise_error(Puppet::Error, %r{Valid values match})
  end

  it 'accepts an binding destination_type' do
    @binding[:destination_type] = :exchange
    @binding[:destination_type].should == :exchange
  end

  it 'accepts a user' do
    @binding[:user] = :root
    @binding[:user].should == :root
  end

  it 'accepts a password' do
    @binding[:password] = :PaSsw0rD
    @binding[:password].should == :PaSsw0rD
  end
end

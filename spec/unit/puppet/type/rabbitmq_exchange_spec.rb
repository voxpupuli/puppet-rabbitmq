require 'puppet'
require 'puppet/type/rabbitmq_exchange'
describe Puppet::Type.type(:rabbitmq_exchange) do
  before do
    @exchange = Puppet::Type.type(:rabbitmq_exchange).new(
      name: 'foo@bar',
      type: :topic,
      internal: false,
      auto_delete: false,
      durable: true
    )
  end
  it 'accepts an exchange name' do
    @exchange[:name] = 'dan@pl'
    @exchange[:name].should == 'dan@pl'
  end
  it 'requires a name' do
    expect do
      Puppet::Type.type(:rabbitmq_exchange).new({})
    end.to raise_error(Puppet::Error, 'Title or name must be provided')
  end
  it 'does not allow whitespace in the name' do
    expect do
      @exchange[:name] = 'b r'
    end.to raise_error(Puppet::Error, %r{Valid values match})
  end
  it 'does not allow names without @' do
    expect do
      @exchange[:name] = 'b_r'
    end.to raise_error(Puppet::Error, %r{Valid values match})
  end

  it 'accepts an exchange type' do
    @exchange[:type] = :direct
    @exchange[:type].should == :direct
  end
  it 'requires a type' do
    expect do
      Puppet::Type.type(:rabbitmq_exchange).new(name: 'foo@bar')
    end.to raise_error(%r{.*must set type when creating exchange.*})
  end
  it 'does not require a type when destroying' do
    expect do
      Puppet::Type.type(:rabbitmq_exchange).new(name: 'foo@bar', ensure: :absent)
    end.not_to raise_error
  end

  it 'accepts a user' do
    @exchange[:user] = :root
    @exchange[:user].should == :root
  end

  it 'accepts a password' do
    @exchange[:password] = :PaSsw0rD
    @exchange[:password].should == :PaSsw0rD
  end
end

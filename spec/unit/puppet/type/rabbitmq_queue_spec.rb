require 'spec_helper'
describe Puppet::Type.type(:rabbitmq_queue) do
  before :each do
    @queue = Puppet::Type.type(:rabbitmq_queue).new(
      :name => 'foo@bar',
      :durable => :true,
      :arguments => {
        'x-message-ttl' => 45,
        'x-dead-letter-exchange' => 'deadexchange'
      }
    )
  end
  it 'should accept an queue name' do
    @queue[:name] = 'dan@pl'
    expect(@queue[:name]).to eq('dan@pl')
  end
  it 'should require a name' do
    expect {
      Puppet::Type.type(:rabbitmq_queue).new({})
    }.to raise_error(Puppet::Error, 'Title or name must be provided')
  end
  it 'should not allow whitespace in the name' do
    expect {
      @queue[:name] = 'b r'
    }.to raise_error(Puppet::Error, /Valid values match/)
  end
  it 'should not allow names without @' do
    expect {
      @queue[:name] = 'b_r'
    }.to raise_error(Puppet::Error, /Valid values match/)
  end

  it 'should accept an arguments with numbers value' do
    @queue[:arguments] = {'x-message-ttl' => 30}
    expect(@queue[:arguments].to_json).to eq("{\"x-message-ttl\":30}")
    expect(@queue[:arguments]['x-message-ttl']).to eq(30)
  end

  it 'should accept an arguments with string value' do
    @queue[:arguments] = {'x-dead-letter-exchange' => 'catchallexchange'}
    expect(@queue[:arguments].to_json).to eq("{\"x-dead-letter-exchange\":\"catchallexchange\"}")
  end

  it 'should accept an queue durable' do
    @queue[:durable] = :true
    expect(@queue[:durable]).to eq(:true)
  end

  it 'should accept a user' do
    @queue[:user] = :root
    expect(@queue[:user]).to eq(:root)
  end

  it 'should accept a password' do
    @queue[:password] = :PaSsw0rD
    expect(@queue[:password]).to eq(:PaSsw0rD)
  end
end

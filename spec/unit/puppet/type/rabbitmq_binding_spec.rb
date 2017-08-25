require 'spec_helper'
describe Puppet::Type.type(:rabbitmq_binding) do
  before :each do
    @binding = Puppet::Type.type(:rabbitmq_binding).new(
      :name => 'foo@blub@bar',
      :destination_type => :queue
    )
  end
  it 'should accept an queue name' do
    @binding[:name] = 'dan@dude@pl'
    expect(@binding[:name]).to eq('dan@dude@pl')
  end
  it 'should require a name' do
    expect {
      Puppet::Type.type(:rabbitmq_binding).new({})
    }.to raise_error(Puppet::Error, 'Title or name must be provided')
  end
  it 'should error when missing source' do
    expect {
      Puppet::Type.type(:rabbitmq_binding).new(
        :name        => 'test binding',
        :destination => 'foobar'
      )
    }.to raise_error(Puppet::Error, /Source and destination must both be defined/)
  end
  it 'should error when missing destination' do
    expect {
      Puppet::Type.type(:rabbitmq_binding).new(
        :name   => 'test binding',
        :source => 'foobar'
      )
    }.to raise_error(Puppet::Error, /Source and destination must both be defined/)
  end
  it 'should accept an binding destination_type' do
    @binding[:destination_type] = :exchange
    expect(@binding[:destination_type]).to eq(:exchange)
  end
  it 'should accept a user' do
    @binding[:user] = :root
    expect(@binding[:user]).to eq(:root)
  end
  it 'should accept a password' do
    @binding[:password] = :PaSsw0rD
    expect(@binding[:password]).to eq(:PaSsw0rD)
  end
end

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
    @binding[:name].should == 'dan@dude@pl'
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
    @binding[:destination_type].should == :exchange
  end
  it 'should accept a user' do
    @binding[:user] = :root
    @binding[:user].should == :root
  end
  it 'should accept a password' do
    @binding[:password] = :PaSsw0rD
    @binding[:password].should == :PaSsw0rD
  end
end

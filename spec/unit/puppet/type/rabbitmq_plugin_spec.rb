require 'puppet'
require 'puppet/type/rabbitmq_plugin'
describe Puppet::Type.type(:rabbitmq_plugin) do
  before do
    @plugin = Puppet::Type.type(:rabbitmq_plugin).new(name: 'foo')
  end
  it 'accepts a plugin name' do
    @plugin[:name] = 'plugin-name'
    @plugin[:name].should == 'plugin-name'
  end
  it 'requires a name' do
    expect do
      Puppet::Type.type(:rabbitmq_plugin).new({})
    end.to raise_error(Puppet::Error, 'Title or name must be provided')
  end
  it 'defaults to a umask of 0022' do
    @plugin[:umask].should == 0o022
  end
  it 'does not allow a non-octal value to be specified' do
    expect do
      @plugin[:umask] = '198'
    end.to raise_error(Puppet::Error, %r{The umask specification is invalid: "198"})
  end
end
